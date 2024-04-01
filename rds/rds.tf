data "aws_security_group" "eks" {
  id = var.eks_cluster_security_group_id
}



resource "aws_db_instance" "this" {
  allocated_storage    = var.rds_allocated_storage
  storage_type         = var.rds_storage_type
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  db_name              = var.rds_db_name
  username             = var.rds_username
  password             = data.aws_secretsmanager_secret_version.rds_password.secret_string
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.this.name
  skip_final_snapshot  = true

   # Enable enhanced monitoring
  monitoring_interval = 60 # Interval in seconds (minimum 60 seconds)
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  # Enable performance insights
  performance_insights_enabled = true
  #cloudwatch log
  enabled_cloudwatch_logs_exports = ["postgresql"]
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/aws/rds/instance/${aws_db_instance.this.id}/postgresql"
  retention_in_days = 7
}

resource "aws_db_subnet_group" "this" {
  name       = var.rds_db_subnet_group_name
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "demo-rds"
  }
}


resource "aws_secretsmanager_secret" "rds_password" {
  name = "rds_password"
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.password.result
}

resource "random_password" "password" {
  length  = 16
  special = true
}


data "aws_vpc" "rds" {
  id = var.vpc_id
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow all inbound traffic from EKS"
  vpc_id      = data.aws_vpc.lb.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = data.aws_security_group.eks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "rds_endpoint" {
  value = aws_db_instance.this.endpoint
}

#### MONITORING WITH CLOUDWATCH #######


resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
  Version = "2012-10-17",
  Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }
  ]
})
}

resource "aws_iam_policy_attachment" "rds_monitoring_attachment" {
  name = "rds-monitoring-attachment"
  roles = [aws_iam_role.rds_monitoring_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}