# Go API Lab — DevOps End-to-End

> A production-style lab: Go REST API → Docker → ECR → EC2 | Lambda → API Gateway | RDS PostgreSQL — all on **AWS Free Tier**, provisioned with Terraform and automated via GitHub Actions.

---

## Architecture

```
                     ┌─────────────────────────────────────────┐
                     │              AWS (us-east-1)             │
                     │                                          │
  ┌─────────┐ push   │  ┌──────────────────────────────────┐   │
  │ GitHub  │───────►│  │           VPC 10.0.0.0/16         │   │
  │ Actions │        │  │                                   │   │
  └────┬────┘        │  │  Public Subnets (10.0.1/2.0/24)  │   │
       │             │  │  ┌───────────────────────────┐   │   │
       │ push image  │  │  │  EC2 t2.micro              │   │   │
       ▼             │  │  │  Docker: go-api:8080       │   │   │
  ┌─────────┐        │  │  │  IAM Role → ECR ReadOnly   │   │   │
  │   ECR   │◄───────│  │  └──────────────┬────────────┘   │   │
  └─────────┘        │  │                 │ 5432            │   │
                     │  │  Private Subnets (10.0.3/4.0/24) │   │
                     │  │  ┌──────────────▼────────────┐   │   │
                     │  │  │  RDS PostgreSQL 15         │   │   │
                     │  │  │  db.t3.micro  20 GB gp2    │   │   │
                     │  │  └───────────────────────────┘   │   │
                     │  └──────────────────────────────────┘   │
                     │                                          │
                     │  ┌──────────────────────────────────┐   │
                     │  │  Lambda (provided.al2, 128 MB)    │   │
                     │  │  GET /health → JSON status        │   │
                     │  └──────────────┬───────────────────┘   │
                     │                 │                        │
                     │  ┌──────────────▼───────────────────┐   │
                     │  │  API Gateway v2 (HTTP API)        │   │
                     │  └──────────────────────────────────┘   │
                     └─────────────────────────────────────────┘

  GitHub Actions CI/CD:
  push → test → build → ECR → SSH deploy to EC2 → build lambda.zip → Lambda update
```

---


## Prerequisites

| Tool | Version |
|------|---------|
| AWS CLI | v2 |
| Terraform | ≥ 1.5 |
| Go | 1.21 |
| Docker | 24+ |
| An AWS account | within Free Tier (first 12 months) |

---

## Quick Start

### 1. Create an EC2 Key Pair (if you don't have one)

```bash
aws ec2 create-key-pair \
  --key-name go-api-lab-key \
  --query 'KeyMaterial' \
  --output text > go-api-lab-key.pem

chmod 400 go-api-lab-key.pem
```

### 2. Create `terraform/terraform.tfvars`

```hcl
# terraform/terraform.tfvars  (NEVER commit this file)
db_username  = "postgres"
db_password  = "SuperSecretPass123!"
ec2_key_name = "go-api-lab-key"
github_repo  = "YOUR_GITHUB_ORG/YOUR_REPO"
```

### 3. Build a placeholder Lambda zip (required for first `terraform apply`)

```bash
cd lambda
go mod tidy
GOARCH=amd64 GOOS=linux go build -tags lambda.norpc -o bootstrap .
zip lambda.zip bootstrap
cd ..
```

### 4. Apply Terraform

```bash
cd terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Terraform prints all outputs at the end. Copy them into your GitHub repo secrets.

### 5. Set GitHub Actions Secrets

Go to `Settings → Secrets and variables → Actions` in your GitHub repo and add:

| Secret | Source |
|--------|--------|
| `AWS_ROLE_ARN` | `terraform output github_actions_role_arn` |
| `AWS_REGION` | `us-east-1` |
| `ECR_URL` | `terraform output ecr_repository_url` |
| `ECR_REPO_NAME` | Last segment of ECR URL (e.g. `go-api-lab-dev`) |
| `EC2_PUBLIC_IP` | `terraform output ec2_public_ip` |
| `EC2_SSH_KEY` | Contents of `go-api-lab-key.pem` |
| `DB_HOST` | `terraform output rds_endpoint` (host only, no port) |
| `DB_USER` | Your `db_username` |
| `DB_PASSWORD` | Your `db_password` |
| `DB_NAME` | `labdb` |
| `LAMBDA_FUNCTION_NAME` | `terraform output lambda_function_name` |

### 6. Trigger the Pipeline

```bash
git add .
git commit -m "feat: initial lab setup"
git push origin main
```

The CI pipeline runs automatically. The CD pipeline is triggered on success.

---

## API Endpoints

Base URL: `http://<EC2_PUBLIC_IP>:8080`

| Method | Path | Description | Status |
|--------|------|-------------|--------|
| `GET` | `/health` | Service health check | 200 |
| `GET` | `/api/users` | List all users | 200 |
| `GET` | `/api/users/:id` | Get user by ID | 200/404 |
| `POST` | `/api/users` | Create user | 201/400 |
| `PUT` | `/api/users/:id` | Update user | 200/404 |
| `DELETE` | `/api/users/:id` | Delete user | 200/404 |

### Example Requests

```bash
# Health check
curl http://<EC2_IP>:8080/health

# Create a user
curl -X POST http://<EC2_IP>:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'

# List users
curl http://<EC2_IP>:8080/api/users

# Lambda health
curl $(terraform output -raw api_gateway_url)/health
```

---

## Local Development

### With Docker Compose (optional)

```bash
# Start postgres + go-api locally
docker compose up -d

# The API is available at http://localhost:8080
```

Create a `docker-compose.yml` in the root:

```yaml
version: "3.9"
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: labdb
    ports: ["5432:5432"]

  api:
    build: ./backend
    ports: ["8080:8080"]
    environment:
      DB_HOST: postgres
      DB_PORT: "5432"
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: labdb
      PORT: "8080"
    depends_on: [postgres]
```

### Without Docker

```bash
cd backend
cp .env.example .env
# Edit .env with your local DB credentials
go mod tidy
go run .
```

---

## Free Tier Compliance Checklist

| Resource | Free Tier Constraint | Status |
|----------|---------------------|--------|
| EC2 | `t2.micro`, ≤ 750 hrs/month | ✅ Hardcoded |
| RDS | `db.t3.micro`, 20 GB gp2, no Multi-AZ | ✅ Enforced |
| ECR | ≤ 500 MB (lifecycle: 3 images max) | ✅ Enforced |
| Lambda | 128 MB, no provisioned concurrency | ✅ Enforced |
| API Gateway | HTTP API v2, ≤ 1M calls/month | ✅ |
| NAT Gateway | **NOT CREATED** (saves ~$32/month) | ✅ Omitted |

---

## Cleanup

> ⚠️ **Run this when you're done to avoid surprise charges after free tier expires.**

```bash
cd terraform
terraform destroy -var-file=terraform.tfvars
```

This removes all AWS resources created by this lab.
