variable "project_name" { type = string }
variable "environment"  { type = string }

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "sg_rds_id" {
  description = "Security group ID to attach to the RDS instance"
  type        = string
}
