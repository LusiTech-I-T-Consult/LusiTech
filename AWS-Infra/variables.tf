variable "primary_region" {
  description = "The primary AWS region for the infrastructure"
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "The disaster recovery AWS region"
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project for resource naming"
  default     = "pilot-light-dr"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  default     = "prod"
}

variable "vpc_cidr_primary" {
  description = "CIDR block for the primary VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_cidr_dr" {
  description = "CIDR block for the DR VPC"
  default     = "10.1.0.0/16"
}

variable "db_instance_class" {
  description = "Instance class for the RDS database"
  default     = "db.t3.medium"
}

variable "ec2_instance_type" {
  description = "Instance type for EC2 servers"
  default     = "t3.medium"
}
