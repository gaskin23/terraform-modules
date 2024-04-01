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

variable "vpc_id" {
  description = "The VPC ID where the RDS instance and EKS are deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the RDS instance"
  type        = list(string)
}

variable "rds_db_subnet_group_name" {
  description = "The name of the DB subnet group for the RDS instance"
  type        = string
}

variable "eks_cluster_security_group_id" {}