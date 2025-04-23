# Pilot Light Disaster Recovery Strategy

## Introduction

This document outlines the pilot light disaster recovery (DR) strategy implemented for our Django application. A pilot light disaster recovery approach keeps essential systems running in a secondary region with minimal resources, allowing for quick recovery in case of a regional failure.

## Disaster Recovery Strategies Overview

There are four main disaster recovery strategies with different trade-offs between cost and recovery time:

1. **Backup & Restore** - Lowest cost, longest recovery time (hours to days)
2. **Pilot Light** - Low cost, medium recovery time (minutes to hours)
3. **Warm Standby** - Medium cost, short recovery time (minutes)
4. **Multi-Site Active/Active** - Highest cost, minimal recovery time (seconds to minutes)

We've chosen the Pilot Light approach because it provides a good balance between cost-effectiveness and recovery time objectives.

## Pilot Light DR Approach

In a pilot light scenario:
- Only essential components are kept running in the DR region (e.g., the database)
- Other components are provisioned but scaled down to minimal or zero capacity (e.g., EC2 instances)
- Minimal resources are used during normal operation, reducing costs
- In case of a disaster, the "pilot light" is "fanned" into a full-scale production environment

## Recovery Objectives

- **Recovery Time Objective (RTO)**: 30 minutes
  - How long it takes to recover the application in the DR region
- **Recovery Point Objective (RPO)**: 5 minutes
  - Maximum acceptable data loss in case of a disaster

## Architecture Components

### Primary Region (eu-west-1)

| Component | Configuration | Purpose |
|-----------|---------------|--------|
| VPC | 10.0.0.0/16 | Network isolation |
| EC2 in ASG | Min: 1, Desired: 2, Max: 3 | Runs Django application |
| RDS | Primary instance | Stores application data |
| S3 | Versioning enabled | Stores static assets and backups |
| ALB | Internet-facing | Routes traffic to EC2 instances |

### DR Region (us-west-2)

| Component | Configuration | Purpose |
|-----------|---------------|--------|
| VPC | 10.1.0.0/16 | Network isolation |
| EC2 in ASG | Min: 0, Desired: 0, Max: 3 | Scaled to zero in normal operation |
| RDS | Read replica | Continuously replicates from primary |
| S3 | Cross-region replication | Mirrors primary region bucket |
| ALB | Internet-facing | Ready to serve traffic during failover |

### Route 53

- Health checks on primary region
- Failover routing policy
- Automatically routes traffic to DR region when primary is unavailable

## Data Synchronization

### Database
- RDS cross-region read replica ensures near real-time data replication
- Read replica can be promoted to primary during failover

### Static Assets
- S3 cross-region replication ensures assets are available in DR region
- Versioning preserves historical versions of objects

### Application State
- Application state is stored in the database and S3
- Regular backups of application state to S3 from primary region

## Security and Secrets Management

- AWS Secrets Manager stores database credentials
- Secrets are replicated to the DR region
- EC2 instances retrieve credentials at launch
- IAM roles with least privilege principles

## Failover Process

### Automatic Failover

1. Route 53 health checks detect failure in primary region
2. DNS automatically routes traffic to the DR region
3. Auto Scaling Group in DR region scales up to handle traffic

### Manual Intervention Required

1. Promote the RDS read replica to become a standalone instance
2. Update database configuration if necessary
3. Monitor the application in the DR region

## Failback Process

Once the primary region is operational again:

1. Restore or rebuild primary region infrastructure
2. Replicate data from DR region back to primary
3. Verify data consistency
4. Update DNS to route traffic back to primary region
5. Scale down DR region resources

## Testing

To ensure the DR strategy works as expected, regular testing is essential:

1. **Tabletop Exercises**: Discuss and walk through disaster scenarios
2. **Component Testing**: Test individual components (e.g., database failover)
3. **Full DR Testing**: Simulate a complete region failure
4. **Regular Schedule**: Test quarterly at minimum

## Monitoring and Alerting

- CloudWatch alarms for critical metrics
- Health checks for application components
- Alerts for failover events and abnormal conditions
- Regular review of DR readiness

## Cost Optimization

The pilot light approach offers significant cost savings compared to a full hot standby:

- EC2 instances scaled to zero in DR region during normal operation
- RDS read replica is the main ongoing cost
- Estimated cost reduction of 60-70% compared to full redundancy

## Documentation and Runbooks

Detailed runbooks are maintained for the following scenarios:

1. Failover procedure
2. Failback procedure
3. DR testing procedure
4. Regular maintenance tasks

## Continuous Improvement

The DR strategy is regularly reviewed and improved based on:

- Test results
- Changes in application architecture
- Updates to AWS services
- Evolving business requirements

## Conclusion

The pilot light disaster recovery strategy provides a cost-effective approach to ensuring business continuity for our Django application. By keeping essential components running in the DR region and automating the failover process, we can achieve our recovery objectives while minimizing ongoing costs.
