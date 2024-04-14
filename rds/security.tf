data "aws_vpc" "rds" {
  id = var.vpc_id
}

module "eks" {
  source = "git::https://github.com/gaskin23/guardian-terraform.git//eks?ref=v1.8.4"
  
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-postgresql-sg"
  description = "Security group for RDS PostgreSQL instance allowing traffic from EKS worker nodes"
  vpc_id      = data.aws_vpc.rds.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = module.aws_security_group.eks_worker_sg.id
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