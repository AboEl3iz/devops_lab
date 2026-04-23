variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in all resource names"
  type        = string
  default     = "go-api-lab"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "db_username" {
  description = "RDS master username — supply via terraform.tfvars or -var flag, never commit"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password — supply via terraform.tfvars or -var flag, never commit"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the PostgreSQL database to create"
  type        = string
  default     = "labdb"
}

# ── EC2 ───────────────────────────────────────────────────────────────────────
# NOTE: ec2_instance_type is intentionally hardcoded to t2.micro inside the
# EC2 module to enforce AWS Free Tier compliance.  Do NOT expose it here.

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair to use for SSH access"
  type        = string
  # Example: "go-api-lab-key"
}

# ── ECR ───────────────────────────────────────────────────────────────────────

variable "ecr_image_tag" {
  description = "Image tag to pull on EC2 first boot (updated by CI/CD pipeline)"
  type        = string
  default     = "latest"
}

# ── GitHub OIDC ───────────────────────────────────────────────────────────────

variable "github_repo" {
  description = "GitHub repository in org/repo format for OIDC trust (e.g. myorg/go-api-lab)"
  type        = string
  # Replace with your real org/repo before applying
  default     = "YOUR_GITHUB_ORG/YOUR_REPO"
}
