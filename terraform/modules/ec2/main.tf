locals {
  name = "${var.project_name}-${var.environment}"
}

# ── Fetch latest Amazon Linux 2023 AMI ID dynamically ────────────────────────

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ── IAM Role for EC2 ─────────────────────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${local.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name}-ec2-role" }
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────
# FREE TIER ENFORCEMENT: instance_type is HARDCODED to t3.micro.
# AWS deprecated t2.micro free tier eligibility for accounts created after ~2022.
# t3.micro is the current free-tier instance (750 hrs/month) in all regions.
# Do NOT expose this as a variable.

resource "aws_instance" "main" {
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t3.micro" # FREE TIER — 750 hrs/month (replaces t2.micro for new accounts)

  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true # EC2 must reach ECR via IGW (no NAT)
  vpc_security_group_ids      = [var.sg_ec2_id]
  key_name                    = var.ec2_key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  # Inject ECR URL, image tag, and DB credentials into the boot script
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    aws_region         = var.aws_region
    ecr_repository_url = var.ecr_repository_url
    ecr_image_tag      = var.ecr_image_tag
    db_host            = var.db_host
    db_user            = var.db_user
    db_password        = var.db_password
    db_name            = var.db_name
  })

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20 # FREE TIER: ≤ 30 GB total EBS
    delete_on_termination = true
  }

  tags = { Name = "${local.name}-ec2" }
}
