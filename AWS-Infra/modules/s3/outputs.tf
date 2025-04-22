output "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "dr_bucket_name" {
  description = "Name of the DR S3 bucket"
  value       = aws_s3_bucket.dr.id
}

output "dr_bucket_arn" {
  description = "ARN of the DR S3 bucket"
  value       = aws_s3_bucket.dr.arn
}