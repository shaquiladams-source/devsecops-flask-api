terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = "us-east-1"
}

variable "repo_name" {
  default = "demo-flask"
}

# 1️⃣ ECR repository to store images
resource "aws_ecr_repository" "this" {
  name                 = var.repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2️⃣ GitHub OIDC provider (once per account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    # GitHub’s OIDC thumbprint (kept updated by AWS docs; adjust if needed)
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

# 3️⃣ IAM role assumable by GitHub Actions for CI/CD
resource "aws_iam_role" "gha_role" {
  name = "gha-ci-cd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            # Limit to your repo & branch
            "token.actions.githubusercontent.com:sub" : "repo:shaquiladams/devsecops-flask-api:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# 4️⃣ Policies: push to ECR + read cluster + kubectl apply (restricted)
# NOTE: For real PoLP, create fine-grained policies & map the role to limited
#RBAC.
resource "aws_iam_policy" "gha_policy" {
  name = "gha-ci-cd-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "eks:DescribeCluster"
        ],
        "Resource": "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "gha_attach" {
  role = aws_iam_role.gha_role.name
  policy_arn = aws_iam_policy.gha_policy.arn
}

