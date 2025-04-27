variable "project_name" {
  description = "Name of the project for resource naming"
  default     = "pilot-light-dr"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  default     = "prod"
}

variable "admin_email" {
  description = "Email address of the administrator"
  default     = "hamdanialhassangandi2020@gmail.com"
  type        = string
}
