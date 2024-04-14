variable "rds_allocated_storage" {
  description = "The allocated storage in gigabytes for the RDS instance"
  type        = number
}

variable "rds_storage_type" {
  description = "The storage type for the RDS instance"
  type        = string
}

variable "rds_engine" {
  description = "The database engine for the RDS instance (e.g., mysql, postgresql)"
  type        = string
}

variable "rds_engine_version" {
  description = "The engine version for the RDS instance"
  type        = string
}

variable "rds_instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
}

variable "rds_db_name" {
  description = "The database name for the RDS instance"
  type        = string
}

variable "rds_username" {
  description = "The username for the RDS database"
  type        = string
  default     = "postgres"
}


variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the RDS instance"
  type        = list(string)
}

variable "rds_db_subnet_group_name" {
  description = "The name of the DB subnet group for the RDS instance"
  type        = string
}

# Existing variables for the RDS instance

variable "rds_cpu_utilization_threshold" {
  description = "The CPU utilization percentage that triggers the CloudWatch alarm for the RDS instance."
  type        = number
  default     = 75
}

variable "cpu_evaluation_periods" {
  description = "The number of evaluation periods for the CPU utilization alarm."
  type        = number
  default     = 2
}

variable "cpu_metric_period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
  default     = 300
}

variable "alert_email_address" {
  description = "The email address to receive alerts for RDS CloudWatch alarms."
  type        = string
  default     = "gashcin23@gmail.com"
}

variable "db_password" {
  description = "for secret manager"
  type        = string
  default     = "db-all-password"
}

variable "eks_name" {
  description = "Name of the cluster."
  type        = string
  default     = "guardian"
}


variable "vpc_id" {
}

variable "eks_worker_security_group_id" {
  
}