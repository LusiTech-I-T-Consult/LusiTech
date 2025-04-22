variable "vpc_id" {
  description = "VPC ID where EC2 instances will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where EC2 instances will be deployed"
  type        = list(string)
}

variable "region" {
  description = "AWS region where EC2 instances will be deployed"
  type        = string
}

variable "lb_security_group_id" {
  description = "Security group ID for the load balancer"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances (required)"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.ami_id) > 4 && substr(var.ami_id, 0, 4) == "ami-"
    error_message = "The ami_id must be a valid AMI ID, starting with \"ami-\"."
  }
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
}

variable "min_size" {
  description = "Minimum size for the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size for the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity for the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "dr_max_size" {
  description = "Maximum size for the DR Auto Scaling Group"
  type        = number
  default     = 3
}

variable "is_primary" {
  description = "Whether this is the primary region (true) or DR region (false)"
  type        = bool
}

variable "target_group_arn" {
  description = "ARN of the target group for the load balancer"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for accessing EC2 instances"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed to SSH into the instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # You should restrict this to your IP range in production
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "db_endpoint" {
  description = "RDS database endpoint"
  type        = string
}

variable "db_name" {
  description = "RDS database name"
  type        = string
}

variable "db_username" {
  description = "RDS database username (may be used for backward compatibility)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_password" {
  description = "RDS database password (may be used for backward compatibility)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_secret_arn" {
  description = "ARN of the secret in Secrets Manager containing database credentials"
  type        = string
  default     = "arn:aws:secretsmanager:eu-west-1:875986301930:secret:pilot-light-dr-prod-db-password-Q7remj"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing application assets"
  type        = string
}
