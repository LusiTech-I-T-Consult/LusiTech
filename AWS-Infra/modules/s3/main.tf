# Primary S3 bucket
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-${var.environment}-${var.primary_region}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-primary-bucket"
    }
  )
}

# Enable versioning on primary bucket
resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for primary bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DR S3 bucket
resource "aws_s3_bucket" "dr" {
  provider = aws.dr
  bucket   = "${var.project_name}-${var.environment}-${var.dr_region}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-dr-bucket"
    }
  )
}

# Enable versioning on DR bucket
resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for DR bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create IAM role for S3 replication
resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Create IAM policy for S3 replication
resource "aws_iam_policy" "replication" {
  provider    = aws.primary
  name        = "${var.project_name}-${var.environment}-s3-replication-policy"
  description = "Policy for S3 cross-region replication"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.primary.arn]
      },
      {
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.primary.arn}/*"]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.dr.arn}/*"]
      }
    ]
  })
}

# Attach replication policy to role
resource "aws_iam_role_policy_attachment" "replication" {
  provider   = aws.primary
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Configure replication on primary bucket
resource "aws_s3_bucket_replication_configuration" "primary" {
  provider = aws.primary

  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.primary]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "EntireBucketReplication"
    status = "Enabled"

    # Optional filter to limit what gets replicated
    # filter {
    #   prefix = ""
    # }

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD"
    }

    # Replicate delete markers
    # delete_marker_replication {
    #   status = "Enabled"
    # }
  }
}

# Create lifecycle policy for primary bucket
resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  rule {
    id     = "transition-to-infrequent-access"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365 # Expire objects after 1 year
    }
  }
}

# Create lifecycle policy for DR bucket
resource "aws_s3_bucket_lifecycle_configuration" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id

  rule {
    id     = "transition-to-infrequent-access"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365 # Expire objects after 1 year
    }
  }
}
