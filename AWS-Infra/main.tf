locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "s3" {
  source = "./modules/s3"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  primary_region = var.primary_region
  dr_region      = var.dr_region
  environment    = var.environment
  project_name   = var.project_name

  tags = local.common_tags
}

module "primary_network" {
  source = "./modules/network"

  providers = {
    aws = aws.primary
  }

  vpc_cidr     = var.vpc_cidr_primary
  region       = var.primary_region
  environment  = var.environment
  project_name = var.project_name

  tags = local.common_tags
}

# Network module for DR region
module "dr_network" {
  source = "./modules/network"

  providers = {
    aws = aws.dr
  }

  vpc_cidr     = var.vpc_cidr_dr
  region       = var.dr_region
  environment  = "${var.environment}-dr"
  project_name = var.project_name

  tags = local.common_tags
}

# RDS module with cross-region replication
module "rds" {
  source = "./modules/rds"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  primary_vpc_id     = module.primary_network.vpc_id
  primary_subnet_ids = module.primary_network.database_subnet_ids
  primary_sg_id      = module.primary_network.db_security_group_id

  dr_vpc_id     = module.dr_network.vpc_id
  dr_subnet_ids = module.dr_network.database_subnet_ids
  dr_sg_id      = module.dr_network.db_security_group_id

  db_instance_class = var.db_instance_class
  primary_region    = var.primary_region
  dr_region         = var.dr_region
  environment       = var.environment
  project_name      = var.project_name

  tags = local.common_tags
}
