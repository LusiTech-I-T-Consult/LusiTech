# Pilot Light Disaster Recovery Architecture

This document describes the disaster recovery architecture implemented for our Django application using the pilot light strategy.

## Architecture Overview
![](../src/dr.drawio.png)

## Components

### Network
- VPC in both primary and DR regions
- Public and private subnets
- Security groups for application tiers

### Compute
- EC2 instances in Auto Scaling Groups
- Primary region: Normal capacity (min size: 1, desired: 2)
- DR region: Minimal capacity (min size: 0, desired: 0) - will scale up during failover

### Database
- RDS database in primary region
- RDS read replica in DR region (can be promoted during failover)

### Storage
- S3 bucket for static assets and application state
- Cross-region replication enabled

### Load Balancing
- Application Load Balancer (ALB) in both regions
- Health checks configured

### DNS
- Route 53 with failover routing policy
- Health checks on primary region
- Automatic failover to DR region when primary is unhealthy

## Failover Process

### Automatic Failover
1. Route 53 health checks detect failure in primary region
2. Traffic automatically redirected to DR region
3. Auto Scaling Group in DR region scales up to handle traffic

### Manual Failover Steps
1. Promote the RDS read replica to become the primary database
2. Scale up the Auto Scaling Group in the DR region
3. Verify application functionality in DR region
4. If desired, manually redirect Route 53 to DR region

### Failback Process
1. Restore primary region infrastructure
2. Set up replication from DR back to primary
3. Verify data consistency
4. Switch Route 53 back to primary region
5. Scale down DR region resources

## Testing

Test the DR setup by:
1. Accessing the DR region directly using the dr.[domain] URL
2. Simulating a failover by disabling health checks
3. Running periodic DR drills

## Monitoring

- CloudWatch alarms for critical metrics
- Health checks for application components
- Regular testing of failover procedures
