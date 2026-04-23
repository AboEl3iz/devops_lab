locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_ecr_repository" "main" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = local.name }
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only last 3 tagged images (free tier: 500 MB/month)"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "sha-"]
          countType     = "imageCountMoreThan"
          # FREE TIER ENFORCEMENT: keep <= 3 to stay under 500 MB ECR limit
          countNumber = 3
        }
        action = { type = "expire" }
      }
    ]
  })
}
