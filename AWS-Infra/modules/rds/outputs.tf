output "primary_db_endpoint" {
  description = "Endpoint of the primary database"
  value       = aws_db_instance.primary.endpoint
}

output "primary_db_instance_id" {
  description = "ID of the primary database instance"
  value       = aws_db_instance.primary.id
}

output "dr_db_endpoint" {
  description = "Endpoint of the DR database replica"
  value       = aws_db_instance.dr_replica.endpoint
}

output "dr_db_instance_id" {
  description = "ID of the DR database instance"
  value       = aws_db_instance.dr_replica.id
}

output "db_username" {
  description = "Username for the database"
  value       = var.db_username
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function for promoting the read replica"
  value       = aws_lambda_function.promote_replica.arn
}
