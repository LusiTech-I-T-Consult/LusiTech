output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "security_group_id" {
  description = "The ID of the security group for the application instances"
  value       = aws_security_group.app_sg.id
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.app.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for the application instances"
  value       = aws_iam_role.app_role.arn
}