variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID where EC2 will be placed"
  type        = string
}

variable "sg_ec2_id" {
  description = "Security group ID to attach to EC2"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL (without tag)"
  type        = string
}

variable "ecr_image_tag" {
  description = "Docker image tag to pull on first boot"
  type        = string
}

variable "db_host" {
  description = "RDS hostname for DB_HOST env var"
  type        = string
}

variable "db_user" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}
