variable "vpc_id" {
  description = "VPC ID where the load balancer will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where the load balancer will be deployed"
  type        = list(string)
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "alarm_actions" {
  description = "List of ARNs for CloudWatch Alarm actions"
  type        = list(string)
  default     = []
}