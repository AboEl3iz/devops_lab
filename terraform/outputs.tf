output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance running the Go API"
  value       = module.ec2.public_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port)"
  value       = module.rds.endpoint
}

output "ecr_repository_url" {
  description = "Full ECR repository URL (without tag)"
  value       = module.ecr.repository_url
}

output "lambda_function_name" {
  description = "Lambda function name — use as LAMBDA_FUNCTION_NAME GitHub secret"
  value       = module.lambda.function_name
}

output "api_gateway_url" {
  description = "API Gateway HTTP API invoke URL (e.g. https://xxx.execute-api.us-east-1.amazonaws.com)"
  value       = module.lambda.api_gateway_url
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions OIDC — use as AWS_ROLE_ARN GitHub secret"
  value       = aws_iam_role.github_actions.arn
}
