# Resource: Create AWS Load Balancer Controller IAM Policy 
data "aws_iam_openid_connect_provider" "lb" {
  arn = var.openid_provider_arn
}

locals {
  oidc_provider_id = element(split("/", data.aws_iam_openid_connect_provider.lb.arn), -1)
}

resource "aws_iam_policy" "lbc_iam_policy" {
  name        = "${var.eks_name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  #policy = data.http.lbc_iam_policy.body
  policy = data.http.lbc_iam_policy.response_body
}

output "lbc_iam_policy_arn" {
  value = aws_iam_policy.lbc_iam_policy.arn
}

# Resource: Create IAM Role 
resource "aws_iam_role" "lbc_iam_role" {
  name       = "${var.eks_name}-lbc-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = [data.aws_iam_openid_connect_provider.lb.arn]
        }
        Condition = {
          StringEquals = {
            "${data.aws_iam_openid_connect_provider.lb.url}:aud" = "sts.amazonaws.com"

          }
        }
      },
    ]
  })
    condition = {
    test     = "StringEquals"
    variable = "${local.oidc_provider_id}:aud"
    values   = ["sts.amazonaws.com"]
    }

  tags = {
    tag-key = "AWSLoadBalancerControllerIAMPolicy"
  }
}

# Associate Load Balanacer Controller IAM Policy to  IAM Role
resource "aws_iam_role_policy_attachment" "lbc_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.lbc_iam_policy.arn
  role       = aws_iam_role.lbc_iam_role.name
}

output "lbc_iam_role_arn" {
  description = "AWS Load Balancer Controller IAM Role ARN"
  value       = aws_iam_role.lbc_iam_role.arn
}