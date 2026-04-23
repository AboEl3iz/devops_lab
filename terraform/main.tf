locals {
  name = "${var.project_name}-${var.environment}"
}

# ── Modules ───────────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_rds_id          = module.vpc.sg_rds_id
}

module "ec2" {
  source = "./modules/ec2"

  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  ec2_key_name        = var.ec2_key_name
  public_subnet_id    = module.vpc.public_subnet_ids[0]
  sg_ec2_id           = module.vpc.sg_ec2_id
  ecr_repository_url  = module.ecr.repository_url
  ecr_image_tag       = var.ecr_image_tag
  db_host             = module.rds.host
  db_user             = var.db_username
  db_password         = var.db_password
  db_name             = var.db_name
}

module "lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment
}

# ── GitHub Actions OIDC ───────────────────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "${local.name}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "${local.name}-github-actions"
  }
}

resource "aws_iam_role_policy_attachment" "github_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "github_lambda" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}
