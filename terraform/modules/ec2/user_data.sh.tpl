#!/bin/bash
set -euxo pipefail

# ── System updates ─────────────────────────────────────────────────────────────
dnf update -y

# ── Install Docker ─────────────────────────────────────────────────────────────
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# ── AWS CLI v2 is pre-installed on Amazon Linux 2023; verify ──────────────────
aws --version

# ── ECR login & pull ─────────────────────────────────────────────────────────
AWS_REGION="${aws_region}"
ECR_URL="${ecr_repository_url}"
IMAGE_TAG="${ecr_image_tag}"

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_URL"

docker pull "$ECR_URL:$IMAGE_TAG"

# ── Run the container ─────────────────────────────────────────────────────────
docker run -d \
  --name go-api \
  --restart always \
  -p 8080:8080 \
  -e DB_HOST="${db_host}" \
  -e DB_PORT="5432" \
  -e DB_USER="${db_user}" \
  -e DB_PASSWORD="${db_password}" \
  -e DB_NAME="${db_name}" \
  -e PORT="8080" \
  "$ECR_URL:$IMAGE_TAG"

echo "go-api container started successfully"
