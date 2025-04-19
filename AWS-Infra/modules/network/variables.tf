variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, dr)"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zone suffixes to use"
  type        = list(string)
  default     = ["a", "b", "c"]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
