locals {
  name = "${var.project_name}-${var.environment}"
}

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.name}-vpc" }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-igw" }
}

# ── Public Subnets (EC2 lives here) ──────────────────────────────────────────

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # Instances launched here get a public IP automatically
  map_public_ip_on_launch = true

  tags = { Name = "${local.name}-public-${count.index + 1}" }
}

# ── Private Subnets (RDS lives here — no internet egress needed) ─────────────

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 3}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${local.name}-private-${count.index + 1}" }
}

# ── Public Route Table → IGW ──────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.name}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NOTE: Private subnets intentionally have NO route table with a NAT Gateway.
# RDS only needs inbound traffic from EC2 — it never needs to reach the internet.
# NAT Gateway costs ~$32/month and is NOT AWS Free Tier. We omit it entirely.

# ── Security Group: EC2 ───────────────────────────────────────────────────────

resource "aws_security_group" "ec2" {
  name        = "${local.name}-sg-ec2"
  description = "Allow SSH and app traffic to EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production
  }

  ingress {
    description = "Go API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-sg-ec2" }
}

# ── Security Group: RDS ───────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "${local.name}-sg-rds"
  description = "Allow PostgreSQL only from EC2 security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # No egress rule needed — RDS doesn't initiate outbound connections
  tags = { Name = "${local.name}-sg-rds" }
}

# ── Data Sources ──────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}
