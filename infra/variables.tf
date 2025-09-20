variable "aws_region" {
  default = "eu-west-1"
}

variable "bucket_name" {
  default = "mqg-quotes-pipeline"
}

variable "environment" {
  default = "dev"
}

variable "db_name" {
  default = "quotes"
}

variable "db_username" {
  default = "etl_user"
}

variable "db_password" {
  description = "DB password"
  sensitive   = true
}

variable "allowed_cidr" {
  default = "0.0.0.0/0" # only for dev — restrict in prod
}
