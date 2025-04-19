variable "primary_region" {
  description = "AWS region for the primary resources"
  type        = string
}

variable "dr_region" {
  description = "AWS region for the DR resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
