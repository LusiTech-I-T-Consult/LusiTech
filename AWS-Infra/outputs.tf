output "primary_vpc_id" {
  value = module.primary_network.vpc_id
}

output "dr_vpc_id" {
  value = module.dr_network.vpc_id
}

output "primary_s3_bucket" {
  value = module.s3.primary_bucket_name
}

output "dr_s3_bucket" {
  value = module.s3.dr_bucket_name
}

output "primary_db_endpoint" {
  value = module.rds.primary_db_endpoint
}

output "dr_db_endpoint" {
  value = module.rds.dr_db_endpoint
}

# Load Balancer outputs
output "primary_lb_dns_name" {
  value = module.primary_lb.lb_dns_name
}

output "dr_lb_dns_name" {
  value = module.dr_lb.lb_dns_name
}

# EC2 outputs
output "primary_asg_name" {
  value = module.primary_ec2.autoscaling_group_name
}

output "dr_asg_name" {
  value = module.dr_ec2.autoscaling_group_name
}

# Route 53 outputs
output "dns_name" {
  value = module.route53.primary_record_name
}

output "primary_direct_url" {
  value = "https://primary.${var.domain_name}"
}

output "dr_direct_url" {
  value = "https://dr.${var.domain_name}"
}
