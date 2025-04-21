output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.app_lb.dns_name
}

output "lb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.app_lb.arn
}

output "lb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.app_lb.zone_id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "security_group_id" {
  description = "The ID of the security group for the load balancer"
  value       = aws_security_group.lb_sg.id
}