resource "aws_db_instance" "this" {
  allocated_storage    = var.rds_allocated_storage
  storage_type         = var.rds_storage_type
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  db_name              = var.rds_db_name
  username             = var.rds_username
  password             = aws_secretsmanager_secret_version.rds_password.secret_string
  # vpc_security_group_ids = [aws_security_group.rds.id]
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


# CloudWatch Metric Alarm for RDS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name                = "rds-high-cpu-${aws_db_instance.this.id}"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.cpu_evaluation_periods
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = var.cpu_metric_period
  statistic                 = "Average"
  threshold                 = var.rds_cpu_utilization_threshold
  alarm_description         = "This alarm triggers when the RDS instance CPU utilization exceeds the defined threshold."
  actions_enabled           = true
  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
}

# SNS Topic for RDS Alerts
resource "aws_sns_topic" "rds_alerts" {
  name = "rds-alerts-${aws_db_instance.this.id}"
}

# SNS Subscription for Email Notifications
resource "aws_sns_topic_subscription" "rds_alerts_email" {
  topic_arn = aws_sns_topic.rds_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_address
}