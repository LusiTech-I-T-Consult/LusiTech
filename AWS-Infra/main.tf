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

# Load Balancer module for Primary region
module "primary_lb" {
  source = "./modules/lb"

  providers = {
    aws = aws.primary
  }

  vpc_id            = module.primary_network.vpc_id
  public_subnet_ids = module.primary_network.public_subnet_ids
  certificate_arn   = var.primary_certificate_arn
  project_name      = var.project_name
  environment       = var.environment

  tags = local.common_tags
}

# Load Balancer module for DR region
module "dr_lb" {
  source = "./modules/lb"

  providers = {
    aws = aws.dr
  }

  vpc_id            = module.dr_network.vpc_id
  public_subnet_ids = module.dr_network.public_subnet_ids
  certificate_arn   = var.dr_certificate_arn
  project_name      = var.project_name
  environment       = "${var.environment}-dr"

  tags = local.common_tags
}

# EC2 module for Primary region
module "primary_ec2" {
  source = "./modules/ec2"

  providers = {
    aws = aws.primary
  }

  vpc_id               = module.primary_network.vpc_id
  subnet_ids           = module.primary_network.public_subnet_ids
  lb_security_group_id = module.primary_lb.security_group_id
  target_group_arn     = module.primary_lb.target_group_arn
  region               = var.primary_region
  project_name         = var.project_name
  environment          = var.environment
  ami_id               = var.primary_ami_id
  instance_type        = var.ec2_instance_type
  ssh_public_key       = var.ssh_public_key
  is_primary           = true

  db_endpoint    = module.rds.primary_db_endpoint
  db_name        = var.db_name
  db_secret_arn  = var.db_secret_arn
  s3_bucket_name = module.s3.primary_bucket_name

  tags = local.common_tags
}

# EC2 module for DR region
module "dr_ec2" {
  source = "./modules/ec2"

  providers = {
    aws = aws.dr
  }

  vpc_id               = module.dr_network.vpc_id
  subnet_ids           = module.dr_network.public_subnet_ids
  lb_security_group_id = module.dr_lb.security_group_id
  target_group_arn     = module.dr_lb.target_group_arn
  region               = var.dr_region
  project_name         = var.project_name
  environment          = "${var.environment}-dr"
  ami_id               = var.dr_ami_id
  instance_type        = var.ec2_instance_type
  ssh_public_key       = var.ssh_public_key
  is_primary           = false

  db_endpoint    = module.rds.dr_db_endpoint
  db_name        = var.db_name
  db_secret_arn  = var.db_secret_arn
  s3_bucket_name = module.s3.dr_bucket_name

  tags = local.common_tags
}

# Route 53 module for failover routing
module "route53" {
  source = "./modules/route53"

  providers = {
    aws = aws.primary # Route53 is global, so we can use either provider
  }

  domain_name            = var.domain_name
  record_name            = var.record_name
  project_name           = var.project_name
  create_route53_records = var.create_route53_records

  primary_lb_dns_name = module.primary_lb.lb_dns_name
  primary_lb_zone_id  = module.primary_lb.lb_zone_id
  dr_lb_dns_name      = module.dr_lb.lb_dns_name
  dr_lb_zone_id       = module.dr_lb.lb_zone_id

  tags = local.common_tags
}


module "sns" {
  source = "./modules/sns"

  providers = {
    aws = aws.primary
  }

  project_name = var.project_name
  environment  = var.environment
  admin_email  = var.admin_email

}

module "lambda_dr_failover" {
  source = "./modules/lambda_dr_failover"

  primary_asg_name      = var.primary_asg_name
  dr_asg_name           = var.dr_asg_name
  sns_topic_arn         = var.sns_topic_arn
  cloudwatch_alarm_arn  = var.cloudwatch_alarm_arn
  cloudwatch_alarm_name = var.cloudwatch_alarm_name
  dr_region             = var.dr_region
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  lambda_function_name  = "${var.project_name}-${var.environment}-dr-failover"
  tags                  = local.common_tags
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-${var.environment}-lambda-policy"
  description = "Policy for Lambda to manage ASGs and send SNS notifications"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action : [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups"
        ],
        Effect : "Allow",
        Resource : "*"
      },
      {
        Action : [
          "sns:Publish"
        ],
        Effect : "Allow",
        Resource : var.sns_topic_arn
      }
    ]
  })
}
