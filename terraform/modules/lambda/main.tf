locals {
  name       = "${var.project_name}-${var.environment}"
  lambda_src = "${path.module}/../../../lambda" # project-root/lambda/
  lambda_zip = "${path.module}/../../../lambda/lambda.zip"

  # Hash computed from Go SOURCE FILES — stable across plan AND apply.
  # Using filebase64sha256(zip) causes a plan/apply inconsistency because
  # null_resource rebuilds the zip *during* apply, changing its hash after
  # Terraform already captured it during plan. Source files never change
  # during apply, so this hash is consistent.
  lambda_source_hash = base64encode(sha256(join("", [
    for f in sort(fileset(local.lambda_src, "*.go")) :
    filesha256("${local.lambda_src}/${f}")
  ])))
}

# ── IAM Role for Lambda ───────────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${local.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name}-lambda-role" }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── Auto-build Lambda zip before creating the function ────────────────────────
# Rebuilds whenever any .go source file changes.
# Requires `go` to be installed on the machine running terraform apply.

resource "null_resource" "build_lambda" {
  triggers = {
    # Re-trigger when any Go source file in lambda/ changes
    source_hash = sha256(join("", [
      for f in sort(fileset(local.lambda_src, "*.go")) :
      filesha256("${local.lambda_src}/${f}")
    ]))
  }

  provisioner "local-exec" {
    working_dir = local.lambda_src
    command     = <<-EOT
      echo "Building Lambda binary..."
      CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build -tags lambda.norpc -o bootstrap .
      zip -o lambda.zip bootstrap
      echo "lambda.zip built successfully"
    EOT
  }
}

# ── Lambda Function ───────────────────────────────────────────────────────────
# Runtime: provided.al2 (Go uses custom runtime; binary must be named "bootstrap")
# FREE TIER: 128 MB memory, no provisioned concurrency

resource "aws_lambda_function" "main" {
  function_name = "${local.name}-health"
  role          = aws_iam_role.lambda.arn

  # Go Lambda: custom runtime — binary compiled as GOOS=linux GOARCH=amd64
  runtime = "provided.al2"
  handler = "bootstrap" # REQUIRED for provided.al2 — must match binary name

  # Path: terraform/modules/lambda/ → ../../.. → project root → lambda/lambda.zip
  filename         = local.lambda_zip
  # Derived from source files (not the zip) so the value is identical at
  # plan time and apply time — even though null_resource rebuilds the zip.
  source_code_hash = local.lambda_source_hash

  # FREE TIER ENFORCEMENT
  memory_size = 128 # minimum; 400,000 GB-seconds/month free
  timeout     = 30

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = { Name = "${local.name}-health" }

  # Ensure zip is built before the function is created/updated
  depends_on = [null_resource.build_lambda]

  lifecycle {
    # Let null_resource handle updates — don't ignore source_code_hash so
    # Lambda always gets the latest build
    ignore_changes = []
  }
}

# ── API Gateway v2 (HTTP API — cheaper than REST API v1) ─────────────────────

resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
    allow_headers = ["Content-Type"]
  }

  tags = { Name = "${local.name}-api" }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.main.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ── Lambda Permission — allow API Gateway to invoke the function ──────────────

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
