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
# IAM role for Session Manager and EC2 to S3
# --------------------------
resource "aws_iam_role" "ssm_role" {
  name = "EC2SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_role_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_role_s3_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "EC2SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
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
  engine_version       = "14"
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
# Bastion EC2 instance
# --------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro" # free tier eligible
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  depends_on                  = [aws_db_instance.quotes]
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  user_data = templatefile("bastion-user-data.sh", {
  db_username  = var.db_username
  db_password  = var.db_password
  db_port      = var.db_port
  db_name      = var.db_name
  db_endpoint  = aws_db_instance.quotes.endpoint
  bucket_name  = var.bucket_name
  api_provider = var.api_provider
  symbol       = var.symbol
  api_key      = var.api_key
  grafana_pass = var.grafana_pass
  grafana_user = var.grafana_user
  })
  tags = {
    Name = "session-bastion"
  }
}

# --------------------------
# Fetch latest Amazon Linux 2 AMI
# --------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
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
# Internet Gateway
# --------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "stock-etl-igw"
  }
}

# --------------------------
# Public subnet
# --------------------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

# --------------------------
# Public route table
# --------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# --------------------------
# Private subnets
# --------------------------
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2b"

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

# Security Group for Bastion
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for DB access
resource "aws_security_group" "db" {
  name        = "quotes-db-sg"
  description = "Allow DB access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id] # only the bastion server.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allowed_cidr]
  }
}
