variable "primary_asg_name" {
  description = "Name of the primary Auto Scaling Group"
  type        = string
}

variable "dr_asg_name" {
  description = "Name of the DR Auto Scaling Group"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for email notification"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "DR AWS region"
  default     = "us-west-2"
}

variable "lambda_role_arn" {
  description = "IAM Role ARN for the Lambda function"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "cloudwatch_alarm_arn" {
  description = "ARN of the CloudWatch alarm that triggers the Lambda function"
  type        = string
}

variable "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm that triggers the Lambda function"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "Name of the project for resource naming"
  default     = "pilot-light-dr"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  default     = "prod"
}
