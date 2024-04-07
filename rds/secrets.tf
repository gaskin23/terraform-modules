provider "aws" {
  region = "us-east-1" # Your AWS region
  alias = "secret"
}
resource "random_password" "mysql_root_password" {
  length  = 16
  special = true
}

resource "random_password" "redis_password" {
  length  = 16
  special = true
}

resource "random_password" "mysql_password" {
  length  = 16
  special = true
}

resource "random_password" "postgresql_password" {
  length  = 16
  special = true
}


resource "aws_secretsmanager_secret" "db_passwords" {
  name        = "db-passwords"
}

resource "aws_secretsmanager_secret_version" "db_passwords_version" {
  secret_id     = aws_secretsmanager_secret.db_passwords.id

  secret_string = jsonencode({
    MYSQL_ROOT_PASSWORD  = random_password.mysql_root_password.result
    REDIS_PASSWORD       = random_password.redis_password.result
    MYSQL_PASSWORD       = random_password.mysql_password.result
    DB_PASSWORD          = random_password.postgresql_password.result
    DB_HOST              = aws_db_instance.this.endpoint
  })
}


####### EXTERNAL SECRET ######

resource "kubernetes_manifest" "db_passwords" {
  depends_on = [aws_secretsmanager_secret_version.db_passwords_version]

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "db-passwords"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        kind = "SecretStore"
        name = "aws-secrets-manager"
      }
      target = {
        name           = "db-passwords"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "mysqlRootPassword"
          remoteRef = {
            key      = aws_secretsmanager_secret.db_passwords.arn
            property = "MYSQL_ROOT_PASSWORD"
          }
        },
        {
          secretKey = "redisPassword"
          remoteRef = {
            key      = aws_secretsmanager_secret.db_passwords.arn
            property = "REDIS_PASSWORD"
          }
        },
        {
          secretKey = "mysqlPassword"
          remoteRef = {
            key      = aws_secretsmanager_secret.db_passwords.arn
            property = "MYSQL_PASSWORD"
          }
        },
        {
          secretKey = "postgresqlPassword"
          remoteRef = {
            key      = aws_secretsmanager_secret.db_passwords.arn
            property = "DB_PASSWORD"
          }
        },
        {
          secretKey = "dbHost"
          remoteRef = {
            key      = aws_secretsmanager_secret.db_passwords.arn
            property = "DB_HOST"
          }
        },
        # Add other keys as necessary
      ]
    }
  }
}