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
