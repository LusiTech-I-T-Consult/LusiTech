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

variable "primary_ami_id" {
  description = "AMI ID for the primary region EC2 instances (required)"
  type        = string
  validation {
    condition     = length(var.primary_ami_id) > 4 && substr(var.primary_ami_id, 0, 4) == "ami-"
    error_message = "The primary_ami_id must be a valid AMI ID, starting with \"ami-\"."
  }
  default = "ami-0182a7ec1f4364ac4"
}

variable "dr_ami_id" {
  description = "AMI ID for the DR region EC2 instances (required)"
  type        = string
  validation {
    condition     = length(var.dr_ami_id) > 4 && substr(var.dr_ami_id, 0, 4) == "ami-"
    error_message = "The dr_ami_id must be a valid AMI ID, starting with \"ami-\"."
  }
  default = "ami-010fc6854b20fbff7"
}

variable "primary_certificate_arn" {
  description = "ARN of the SSL certificate for the primary region load balancer"
  type        = string
  default     = ""
}

variable "dr_certificate_arn" {
  description = "ARN of the SSL certificate for the DR region load balancer"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key for accessing EC2 instances"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name for Route 53 records"
  type        = string
  default     = "lusitechitconsult.com"
}

variable "record_name" {
  description = "The record name for Route 53 records (subdomain - optional)"
  type        = string
  default     = ""
}

variable "create_route53_records" {
  description = "Whether to create Route 53 records. Set to false if you don't have a hosted zone yet."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "django_db"
}

variable "db_secret_arn" {
  description = "ARN of the secret in Secrets Manager containing database credentials"
  type        = string
  default     = "arn:aws:secretsmanager:eu-west-1:875986301930:secret:pilot-light-dr-prod-db-password-Q7remj"
}

variable "dr_certificate_arn" {
  description = "ARN of the SSL certificate for the DR region load balancer"
  type        = string
  default     = "arn:aws:acm:us-west-2:875986301930:certificate/49c57cb8-e468-441f-9750-074ef4954d66"
}

variable "primary_certificate_arn" {
  description = "ARN of the SSL certificate for the primary region load balancer"
  type        = string
  default     = "arn:aws:acm:eu-west-1:875986301930:certificate/3339f69a-b097-4707-9b5b-f766d63ab35b"
}
