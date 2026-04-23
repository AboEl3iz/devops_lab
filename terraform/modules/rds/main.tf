locals {
  name = "${var.project_name}-${var.environment}"
}

# ── DB Subnet Group (requires 2 AZs for RDS) ─────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${local.name}-rds-subnet-group" }
}

# ── RDS PostgreSQL ─────────────────────────────────────────────────────────────
# FREE TIER: db.t3.micro, 20 GB gp2, no Multi-AZ, no backups, no read replicas

resource "aws_db_instance" "main" {
  identifier = "${local.name}-rds"

  # Engine
  engine         = "postgres"
  engine_version = "16" # Major version only — AWS picks the latest available patch

  # FREE TIER ENFORCEMENT
  instance_class    = "db.t3.micro" # 750 hrs/month free
  allocated_storage = 20            # 20 GB free tier allowance
  storage_type      = "gp2"

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.sg_rds_id]
  publicly_accessible    = false # RDS stays private

  # FREE TIER: disable features that incur cost
  multi_az                = false # Multi-AZ doubles cost — NOT free tier
  backup_retention_period = 0     # Disables automated backups (no extra storage cost)
  skip_final_snapshot     = true  # Lab teardown: no snapshot needed

  # Performance Insights free tier: 7 days retention
  performance_insights_enabled = false

  apply_immediately = true

  tags = { Name = "${local.name}-rds" }
}
