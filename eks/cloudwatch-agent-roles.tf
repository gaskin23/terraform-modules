data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

resource "aws_iam_role" "cloudwatch_agent_eks_role" {
  name = "CloudWatchAgentEKSRole"

  # Use the OIDC issuer URL from the EKS cluster to dynamically set the trust relationship
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "TrustMyRole",
        Effect   = "Allow",
        Principal = {
          Federated = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/")}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:cloudwatch-agent-sa"
          }
        }
      },
    ]
  })
}


resource "aws_iam_policy" "cloudwatch_agent_policy" {
  name        = "CloudWatchAgentServerPolicy"
  path        = "/"
  description = "Policy for CloudWatch agent on EKS"
  policy = file("manifests/cloudwatchpolicy.json")
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  role       = aws_iam_role.cloudwatch_agent_eks_role.name
  policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn
}