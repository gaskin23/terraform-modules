provider "aws" {
  region = "us-east-1" # Your AWS region
  alias = "secret"
}

resource "random_password" "mysql_root_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "mysql_root_password" {
  name = "MYSQL_ROOT_PASSWORD"
}

resource "aws_secretsmanager_secret_version" "mysql_root_password_version" {
  secret_id     = aws_secretsmanager_secret.mysql_root_password.id
  secret_string = "{\"MYSQL_ROOT_PASSWORD\":\"${random_password.mysql_root_password.result}\"}"
}

resource "random_password" "redis_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "redis_password" {
  name = "REDIS_PASSWORD"
}

resource "aws_secretsmanager_secret_version" "redis_password_version" {
  secret_id     = aws_secretsmanager_secret.redis_password.id
  secret_string = "{\"REDIS_PASSWORD\":\"${random_password.redis_password.result}\"}"
}

resource "random_password" "mysql_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "mysql_password" {
  name = "MYSQL_PASSWORD"
}

resource "aws_secretsmanager_secret_version" "mysql_password_version" {
  secret_id     = aws_secretsmanager_secret.mysql_password.id
  secret_string = "{\"MYSQL_PASSWORD\":\"${random_password.mysql_password.result}\"}"
}