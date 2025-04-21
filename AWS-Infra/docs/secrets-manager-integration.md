# AWS Secrets Manager Integration for Database Credentials

This document explains how the database credentials are managed using AWS Secrets Manager in our pilot light disaster recovery architecture.

## Overview

Instead of hardcoding database credentials in Terraform variables or environment variables, we use AWS Secrets Manager to securely store and manage these credentials. This approach provides several benefits:

1. Increased security by avoiding plain text credentials in configuration files
2. Centralized credential management across primary and DR regions
3. Simplified credential rotation
4. Audit trail for credential access

## Implementation

### 1. Creating the Secret in Secrets Manager

The database password is generated using Terraform's `random_password` resource and stored in AWS Secrets Manager. Here's an example of how to create this in your Terraform code:

```hcl
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}/${var.environment}/db-credentials"
  description = "Database credentials for ${var.project_name} ${var.environment}"
  
  # Enable replication to DR region for disaster recovery
  replica {
    region = var.dr_region
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}
```

### 2. EC2 IAM Role Permissions

The EC2 instances in both primary and DR regions have IAM permissions to access the secret:

```hcl
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Allow EC2 instances to access secrets in Secrets Manager"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = [
          var.db_secret_arn
        ]
      }
    ]
  })
}
```

### 3. Retrieving Credentials in User Data Script

When EC2 instances boot up, they retrieve the database credentials from Secrets Manager in the user data script:

```bash
# Get database credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id ${db_secret_arn} --region ${aws_region} --query SecretString --output text)
DB_USERNAME=$(echo $DB_SECRET | jq -r '.username')
DB_PASSWORD=$(echo $DB_SECRET | jq -r '.password')

# Set environment variables
echo "export DB_HOST=${db_endpoint}" >> /etc/environment
echo "export DB_NAME=${db_name}" >> /etc/environment
echo "export DB_USER=$DB_USERNAME" >> /etc/environment
echo "export DB_PASSWORD=$DB_PASSWORD" >> /etc/environment
```

## Credential Rotation

To rotate the database credentials:

1. Generate a new password in Secrets Manager
2. Update the RDS instance with the new password
3. The next time instances are refreshed (e.g., during an Auto Scaling event), they will pick up the new credentials

## Security Considerations

1. The secret ARN should be passed to the EC2 module, not the actual credentials
2. IAM policies should follow the principle of least privilege
3. Enable CloudTrail logging for Secrets Manager API calls
4. Consider using AWS KMS for additional encryption

## In the Event of a Disaster

During a disaster recovery event:

1. The same secret is already replicated to the DR region
2. EC2 instances in the DR region retrieve credentials from the replicated secret
3. No manual intervention is required for credential management during failover