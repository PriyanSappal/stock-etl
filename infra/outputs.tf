# --------------------------
# Outputs for S3
# --------------------------
output "s3_bucket_name" {
  description = "Name of the S3 bucket used for storing parquet data"
  value       = aws_s3_bucket.quotes.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.quotes.arn
}

# --------------------------
# Outputs for RDS
# --------------------------
output "rds_endpoint" {
  description = "PostgreSQL RDS endpoint to connect to"
  value       = aws_db_instance.quotes.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.quotes.port
}

output "rds_db_name" {
  description = "Database name for RDS instance"
  value       = aws_db_instance.quotes.db_name
}

# --------------------------
# Outputs for IAM role (for GitHub OIDC)
# --------------------------
output "github_actions_role_arn" {
  description = "IAM Role ARN that GitHub Actions can assume via OIDC"
  value       = aws_iam_role.github_actions_role.arn
}

# --------------------------
# Outputs for EC2
# --------------------------
output "bastion_public_ip" {
  description = "Public IP address of the Bastion EC2 instance"
  value       = aws_instance.bastion.public_ip
}