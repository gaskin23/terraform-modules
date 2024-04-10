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
  name        = "db-passwords3"
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
  depends_on = [aws_secretsmanager_secret_version.db_passwords_version, aws_iam_role.external_secrets_operator_role]

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "db-passwords"
      namespace = "default"
    }
    spec = {
      refreshInterval = "1m"
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

############# EXTERNAL SECRETS ############

resource "aws_iam_policy" "external_secrets_policy" {
  name        = "ExternalSecretsManagerPolicy"
  description = "Allows access to Secrets Manager and SSM Parameter Store"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DescribeParameters",
          "ssm:GetParameterHistory",
        ],
        Resource = "*"
      },
    ]
  })
}




data "aws_eks_cluster" "external" {
  name = var.eks_name
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "external_secrets_operator_role" {
  name = "external_secrets_operator_role"

  # Use the OIDC issuer URL from the EKS cluster to dynamically set the trust relationship
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "TrustMyRole",
        Effect   = "Allow",
        Principal = {
          Federated = "${replace(data.aws_eks_cluster.external.identity[0].oidc[0].issuer, "https://", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/")}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.external.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com",
            "${replace(data.aws_eks_cluster.external.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:external-sa"
          }
        }
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "secrets_manager_access_attachment" {
  role       = aws_iam_role.external_secrets_operator_role.name
  policy_arn = aws_iam_policy.external_secrets_policy.arn
}


data "kubectl_file_documents" "store" {
  content = file("manifests/externalsecretstore.yaml")
}

resource "kubectl_manifest" "secret_store" {
  depends_on = [ aws_iam_role.external_secrets_operator_role ]
  for_each  = data.kubectl_file_documents.store.manifests
  yaml_body = each.value
  wait = true
  server_side_apply = true
}