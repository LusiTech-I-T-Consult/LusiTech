variable "primary_vpc_id" {
  description = "ID of the VPC in the primary region"
  type        = string
}

variable "primary_subnet_ids" {
  description = "List of subnet IDs for the database in the primary region"
  type        = list(string)
}

variable "primary_sg_id" {
  description = "ID of the security group for the database in the primary region"
  type        = string
}

variable "dr_vpc_id" {
  description = "ID of the VPC in the DR region"
  type        = string
}

variable "dr_subnet_ids" {
  description = "List of subnet IDs for the database in the DR region"
  type        = list(string)
}

variable "dr_sg_id" {
  description = "ID of the security group for the database in the DR region"
  type        = string
}

variable "db_instance_class" {
  description = "Instance class for the database"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for the database in GB"
  type        = number
  default     = 10
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
}

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
