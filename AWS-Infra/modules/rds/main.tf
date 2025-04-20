resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  provider    = aws.primary
  name        = "${var.project_name}-${var.environment}-db-password"
  description = "Database password for ${var.project_name} ${var.environment}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  provider  = aws.primary
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# Create DB subnet group in primary region
resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.primary_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-db-subnet-group"
    }
  )
}

# Create DB subnet group in DR region
resource "aws_db_subnet_group" "dr" {
  provider   = aws.dr
  name       = "${var.project_name}-${var.environment}-dr-db-subnet-group"
  subnet_ids = var.dr_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-dr-db-subnet-group"
    }
  )
}

# Create parameter group for MySQL in primary region
resource "aws_db_parameter_group" "primary" {
  provider    = aws.primary
  name        = "${var.project_name}-${var.environment}-param-group"
  family      = "mysql8.0"
  description = "Parameter group for ${var.project_name} ${var.environment} database"

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  tags = var.tags
}

# Create parameter group for MySQL in DR region
resource "aws_db_parameter_group" "dr" {
  provider    = aws.dr
  name        = "${var.project_name}-${var.environment}-dr-param-group"
  family      = "mysql8.0"
  description = "Parameter group for ${var.project_name} ${var.environment} DR database"

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  tags = var.tags
}

# Create primary RDS instance
resource "aws_db_instance" "primary" {
  provider          = aws.primary
  engine            = "mysql"
  engine_version    = "8.0"
  identifier        = "${var.project_name}-${var.environment}"
  username          = var.db_username
  password          = random_password.db_password.result
  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true

  vpc_security_group_ids = [var.primary_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.primary.name
  parameter_group_name   = aws_db_parameter_group.primary.name

  multi_az                = true
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"
  apply_immediately       = true

  # This enables replication
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-primary-db"
    }
  )
}

# Create DR read replica in the DR region
resource "aws_db_instance" "dr_replica" {
  provider            = aws.dr
  identifier          = "${var.project_name}-${var.environment}-dr-replica"
  replicate_source_db = aws_db_instance.primary.arn
  instance_class      = var.db_instance_class

  # Explicitly enable encryption and specify a KMS key in the DR region
  storage_encrypted = true
  kms_key_id        = aws_kms_key.dr_rds_key.arn # You'll need to create this key

  vpc_security_group_ids = [var.dr_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.dr.name
  parameter_group_name   = aws_db_parameter_group.dr.name

  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "sun:04:30-sun:05:30"
  apply_immediately         = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-dr-replica-final-snapshot"

  # Auto minor version upgrades should match the primary
  auto_minor_version_upgrade = aws_db_instance.primary.auto_minor_version_upgrade

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-dr-replica-db"
    }
  )
}

# Create a KMS key in the DR region for RDS encryption
resource "aws_kms_key" "dr_rds_key" {
  provider                = aws.dr
  description             = "KMS key for RDS encryption in DR region"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "dr_rds_key_alias" {
  provider      = aws.dr
  name          = "alias/${var.project_name}-${var.environment}-dr-rds-key"
  target_key_id = aws_kms_key.dr_rds_key.key_id
}

# Create CloudWatch metrics alarm for replication lag
resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  provider            = aws.dr
  alarm_name          = "${var.project_name}-${var.environment}-replication-lag-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 300 # 5 minutes
  alarm_description   = "This alarm monitors RDS replication lag"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.dr_replica.id
  }

  alarm_actions = [
    # Optional: Add SNS topic ARN for alerts
  ]

  tags = var.tags
}

# Lambda function for promoting read replica in DR scenario
resource "aws_iam_role" "lambda_role" {
  provider = aws.dr
  name     = "${var.project_name}-${var.environment}-rds-promotion-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "lambda_policy" {
  provider    = aws.dr
  name        = "${var.project_name}-${var.environment}-rds-promotion-lambda-policy"
  description = "Policy for RDS promotion Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:PromoteReadReplica",
          "rds:DescribeDBInstances",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  provider   = aws.dr
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "promote_replica" {
  provider      = aws.dr
  function_name = "${var.project_name}-${var.environment}-promote-rds-replica"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  timeout       = 60

  filename = "${path.module}/promote_replica_lambda.zip"

  environment {
    variables = {
      DB_INSTANCE_IDENTIFIER = aws_db_instance.dr_replica.id
    }
  }

  tags = var.tags
}
