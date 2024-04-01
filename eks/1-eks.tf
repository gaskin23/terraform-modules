data "aws_vpc" "eks" {
  id = var.vpc_id
}

resource "aws_iam_role" "eks" {
  name = "${var.env}-${var.eks_name}-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_eks_cluster" "this" {
  name     = "${var.env}-${var.eks_name}"
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids = [aws_security_group.this.id]
    subnet_ids = var.subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks,aws_cloudwatch_log_group.this]
}

resource "aws_security_group" "this" {
  name        = "${var.env}-${var.eks_name}-eks-sg"
  description = "Security group for ${var.env} environment EKS cluster"
  vpc_id      = data.aws_vpc.eks.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.eks_name}-eks-sg"
  }
}


resource "aws_cloudwatch_log_group" "this" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/${var.eks_name}/cluster"
  retention_in_days = 7

  # ... potentially other configuration ...
}