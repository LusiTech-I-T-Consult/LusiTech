variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "lusitech"
}