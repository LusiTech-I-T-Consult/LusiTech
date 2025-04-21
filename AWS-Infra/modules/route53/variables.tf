variable "domain_name" {
  description = "The domain name for Route 53 records"
  type        = string
}

variable "create_route53_records" {
  description = "Whether to create Route 53 records. Set to false if you don't have a hosted zone yet."
  type        = bool
  default     = true
}

variable "record_name" {
  description = "The record name for Route 53 records (subdomain - optional)"
  type        = string
  default     = ""
}

variable "primary_lb_dns_name" {
  description = "DNS name of the primary load balancer"
  type        = string
}

variable "primary_lb_zone_id" {
  description = "Canonical hosted zone ID of the primary load balancer"
  type        = string
}

variable "dr_lb_dns_name" {
  description = "DNS name of the DR load balancer"
  type        = string
}

variable "dr_lb_zone_id" {
  description = "Canonical hosted zone ID of the DR load balancer"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}