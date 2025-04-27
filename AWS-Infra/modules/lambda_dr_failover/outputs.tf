output "lambda_function_arn" {
  description = "The ARN of the lambda function"
  value       = aws_lambda_function.dr_failover.arn
}
