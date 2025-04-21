output "primary_health_check_id" {
  description = "ID of the health check for the primary load balancer"
  value       = var.create_route53_records ? aws_route53_health_check.primary[0].id : ""
}

output "hosted_zone_id" {
  description = "The ID of the hosted zone"
  value       = var.create_route53_records ? data.aws_route53_zone.selected[0].zone_id : ""
}

output "primary_record_name" {
  description = "FQDN of the primary record"
  value       = var.create_route53_records ? aws_route53_record.primary[0].fqdn : ""
}

output "dr_record_name" {
  description = "FQDN of the DR record"
  value       = var.create_route53_records ? aws_route53_record.dr[0].fqdn : ""
}