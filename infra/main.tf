provider "aws" {
  region = var.aws_region
}
# --------------------------
# IAM Role for GitHub Actions (OIDC)
# --------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub OIDC root CA
}

# IAM role that GitHub Actions will assume
resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsTerraformRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # Lock down to your repo for extra security
            "token.actions.githubusercontent.com:sub" = "repo:PriyanSappal/stock-etl:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# IAM policy with permissions for Terraform (S3 + RDS)
resource "aws_iam_policy" "terraform_policy" {
  name        = "TerraformPolicy"
  description = "Permissions for Terraform GitHub Actions pipeline"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:*",
          "rds:*",
          "ec2:Describe*",
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.terraform_policy.arn
}

# --------------------------
# S3 bucket for Parquet data
# --------------------------
resource "aws_s3_bucket" "quotes" {
  bucket = var.bucket_name

  tags = {
    Name        = "quotes-data"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "quotes" {
  bucket = aws_s3_bucket.quotes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------
# RDS PostgreSQL instance
# --------------------------
resource "aws_db_instance" "quotes" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "14.11"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  multi_az             = false
  deletion_protection  = false
  publicly_accessible  = false
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name = aws_db_subnet_group.quotes.name
}

# --------------------------
# VPC
# --------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "stock-etl-vpc"
  }
}

# --------------------------
# Private subnets
# --------------------------
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "private-subnet-b"
  }
}

# --------------------------
# DB Subnet group (RDS requires at least 2 subnets)
# --------------------------
resource "aws_db_subnet_group" "quotes" {
  name       = "quotes-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "quotes-db-subnet-group"
  }
}

# Security group for DB access
resource "aws_security_group" "db" {
  name        = "quotes-db-sg"
  description = "Allow DB access"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr] # e.g. "0.0.0.0/0" for dev (not secure)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
