# Terraform Plan and Deployment Guide

This document provides instructions for testing, deploying, and managing the Pilot Light Disaster Recovery infrastructure.

## Prerequisites

Before deploying the infrastructure, ensure you have:

1. AWS CLI configured with appropriate credentials
2. Terraform v1.0.0 or later installed
3. A registered domain name in Route 53
4. SSL certificates for your domain in both regions (via ACM)
5. Generated SSH key pair for EC2 instance access

## Setting up Variables

Create a `terraform.tfvars` file with the following content:

```hcl
primary_region        = "eu-west-1"
dr_region             = "us-west-2"
project_name          = "your-app-name"
environment           = "prod"

vpc_cidr_primary      = "10.0.0.0/16"
vpc_cidr_dr           = "10.1.0.0/16"

db_instance_class     = "db.t3.medium"
ec2_instance_type     = "t3.medium"

# AMI IDs (use recent Ubuntu/Amazon Linux AMIs for each region)
primary_ami_id        = "ami-12345678901234567"
dr_ami_id             = "ami-76543210987654321"

# SSL certificates (create these in AWS Certificate Manager)
primary_certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/uuid"
dr_certificate_arn      = "arn:aws:acm:us-west-2:123456789012:certificate/uuid"

# SSH key (use your public key)
ssh_public_key        = "ssh-rsa AAAA..."

# Domain and DB settings
domain_name           = "yourdomain.com"
record_name           = "app"  # This will create app.yourdomain.com
db_name               = "django_db"
db_username           = "dbadmin"
db_password           = "SecurePassword123"  # Use AWS Secrets Manager in production
```

## Testing the Plan

To test your Terraform plan without making any changes:

```bash
cd website/AWS-Infra
terraform init
terraform plan -out=dr-plan.tfplan
```

Review the plan to ensure it will create the resources as expected.

## Deploying the Infrastructure

To deploy the infrastructure:

```bash
terraform apply "dr-plan.tfplan"
```

Or to plan and apply in one step:

```bash
terraform apply
```

## Testing the Disaster Recovery Setup

### Access Test

1. Access your application via the main URL (e.g., `app.yourdomain.com`)
2. Access your application via the primary direct URL (e.g., `primary.yourdomain.com`)
3. Access your application via the DR direct URL (e.g., `dr.yourdomain.com`) - Note: This may not work until scaled up

### Simulating a Disaster

To simulate a disaster and test failover:

1. In the AWS Console, navigate to Route 53 health checks
2. Disable the health check for the primary region
3. Wait for DNS propagation (typically 60-180 seconds)
4. Access your main URL to verify it now routes to the DR region
5. You may need to manually scale up the DR region using:

```bash
aws autoscaling set-desired-capacity \
    --auto-scaling-group-name $(terraform output -raw dr_asg_name) \
    --desired-capacity 2 \
    --region us-west-2
```

### Testing Database Failover

To test database failover:

1. In the AWS Console, navigate to RDS
2. Select the read replica in the DR region
3. Choose "Promote" to make it a standalone database
4. Update the application configuration to use the new primary DB

## Failback Procedure

After the issue in the primary region is resolved:

1. Re-establish replication from DR to primary
2. Verify data consistency
3. Re-enable the Route 53 health check for the primary region
4. Monitor the application to ensure proper routing
5. Scale down resources in the DR region:

```bash
aws autoscaling set-desired-capacity \
    --auto-scaling-group-name $(terraform output -raw dr_asg_name) \
    --desired-capacity 0 \
    --region us-west-2
```

## Cost Optimization

The Pilot Light strategy helps minimize costs while maintaining disaster recovery capabilities:

- EC2 instances in DR region are kept at minimal or zero capacity during normal operation
- Only scaled up during failover or testing
- RDS read replica serves as a backup and can be used for read operations
- Regular testing ensures the DR strategy works when needed

## Monitoring

Set up additional monitoring:

1. Create CloudWatch dashboards for both regions
2. Configure alarms for key metrics (CPU, memory, disk space)
3. Set up notifications for failover events
4. Regularly test the failover process

## Security Considerations

- Rotate database credentials regularly
- Use AWS Secrets Manager for sensitive information
- Restrict SSH access to specific IP ranges
- Enable AWS Config and CloudTrail for compliance and auditing