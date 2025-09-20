provider "aws" {
  region = var.aws_region
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

# Optional: make sure bucket blocks public access
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
  publicly_accessible  = false
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.db.id]
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
