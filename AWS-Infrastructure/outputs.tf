output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the created VPC"
}

output "public_subnet_id" {
  value       = module.vpc.public_subnet_ids
  description = "IDs of the created public subnets"
}

output "security_group" {
  value       = module.security_group.security_group_id
  description = "ID of the created security group"
}

output "ec2_instance_id" {
  value       = module.ec2_instance.instance_id
  description = "ID of the created EC2 instance"
}

# output "eks_cluster_id" {
#   value       = module.eks.cluster_id
#   description = "ID of the created EKS cluster"
# }

# output "eks_cluster_version" {
#   value       = module.eks.cluster_version
#   description = "Version of the created EKS cluster"
# }

# output "eks_cluster_endpoint" {
#   value       = module.eks.cluster_endpoint
#   description = "Endpoint of the created EKS cluster"
# }
