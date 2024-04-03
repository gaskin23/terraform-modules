provider "aws" {
  region = "us-east-1" # Your AWS region
}

locals {
  secrets = jsondecode(file("${path.module}~/aws-secret/secrets.txt"))
}

resource "aws_secretsmanager_secret" "mysql_root_password" {
  name = "MYSQL_ROOT_PASSWORD"
}

resource "aws_secretsmanager_secret_version" "mysql_root_password_version" {
  secret_id     = aws_secretsmanager_secret.mysql_root_password.id
  secret_string = jsonencode({
    MYSQL_ROOT_PASSWORD = local.secrets.MYSQL_ROOT_PASSWORD
  })
}

resource "aws_secretsmanager_secret" "redis_password" {
  name = "REDIS_PASSWORD"
}

resource "aws_secretsmanager_secret_version" "redis_password_version" {
  secret_id     = aws_secretsmanager_secret.redis_password.id
  secret_string = jsonencode({
    REDIS_PASSWORD = local.secrets.REDIS_PASSWORD
  })
}

resource "aws_secretsmanager_secret" "mysql_password" {
  name = "MYSQL_PASSWORD"
}

resource "aws_secretsmanager_secret_version" "mysql_password_version" {
  secret_id     = aws_secretsmanager_secret.mysql_password.id
  secret_string = jsonencode({
    MYSQL_PASSWORD = local.secrets.MYSQL_PASSWORD
  })
}