data "aws_vpc" "rds" {
  id = var.vpc_id
}

data "aws_security_group" "rds_eks" {
  id = var.eks_worker_security_group_id
}


resource "aws_security_group" "rds_sg" {
  name        = "rds-postgresql-sg"
  description = "Security group for RDS PostgreSQL instance allowing traffic from EKS worker nodes"
  vpc_id      = data.aws_vpc.rds.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = data.aws_security_group.rds_eks.id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDSPostgreSQLSecurityGroup"
  }
}