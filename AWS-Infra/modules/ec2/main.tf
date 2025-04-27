# EC2 Module for Pilot Light Disaster Recovery

resource "aws_key_pair" "app_key" {
  count      = var.ssh_public_key != "" ? 1 : 0
  provider   = aws
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = var.ssh_public_key
}

# Generate a random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Security group for the application
resource "aws_security_group" "app_sg" {
  provider    = aws
  name        = "${var.project_name}-${var.environment}-app-sg-${random_id.suffix.hex}"
  description = "Security group for the application servers"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic from the load balancer security group and internet
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.lb_security_group_id]
  }

  # Also allow direct HTTP access for testing
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from internet for testing"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic on port 8000 for application"
  }

  # Allow HTTPS traffic from the load balancer security group
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.lb_security_group_id]
  }

  # Also allow direct HTTPS access for testing
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet for testing"
  }

  # Allow SSH from specified CIDR blocks for management
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app-sg"
    }
  )
}

# Launch template for the application
# Validate that AMI ID is provided
resource "null_resource" "validate_ami" {
  count = var.ami_id == "" ? "AMI ID cannot be empty" : 0
}

resource "aws_launch_template" "app" {
  provider      = aws
  name          = "${var.project_name}-${var.environment}-app-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = length(aws_key_pair.app_key) > 0 ? aws_key_pair.app_key[0].key_name : null

  user_data = base64encode(templatefile("${path.module}/templates/user_data.tpl", {
    db_endpoint   = var.db_endpoint
    db_name       = var.db_name
    db_username   = var.db_username
    db_password   = var.db_password
    s3_bucket     = var.s3_bucket_name
    aws_region    = var.region
    project_name  = var.project_name
    environment   = var.environment
    is_primary    = var.is_primary
    db_secret_arn = var.db_secret_arn
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.volume_size
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-app-instance"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for the application
resource "aws_autoscaling_group" "app" {
  provider                  = aws
  name                      = "${var.project_name}-${var.environment}-app-asg"
  min_size                  = var.is_primary ? var.min_size : 0
  max_size                  = var.is_primary ? var.max_size : var.dr_max_size
  desired_capacity          = var.is_primary ? var.desired_capacity : 0
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "EC2" # Changed from ELB to EC2 for initial troubleshooting
  health_check_grace_period = 300   # 5 minutes grace period for initialization

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  # For DR region, we keep instances at minimum or zero to save costs
  # During DR event, this should be scaled up

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# IAM role for EC2 instances to access S3 and other services
resource "aws_iam_role" "app_role" {
  provider = aws
  name     = "${var.project_name}-${var.environment}-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Policy for accessing S3 bucket
resource "aws_iam_policy" "s3_access" {
  provider    = aws
  name        = "${var.project_name}-${var.environment}-s3-access"
  description = "Allow EC2 instances to access the S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# Policy for accessing Secrets Manager
resource "aws_iam_policy" "secrets_access" {
  provider    = aws
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Allow EC2 instances to access secrets in Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          var.db_secret_arn
        ]
      }
    ]
  })
}

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "s3_access" {
  provider   = aws
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  provider   = aws
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  provider   = aws
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for the EC2 instances
resource "aws_iam_instance_profile" "app_profile" {
  provider = aws
  name     = "${var.project_name}-${var.environment}-app-profile"
  role     = aws_iam_role.app_role.name
}

# CloudWatch alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  provider            = aws
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# CloudWatch alarm for low CPU utilization
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  provider            = aws
  alarm_name          = "${var.project_name}-${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# Auto scaling policies
resource "aws_autoscaling_policy" "scale_up" {
  provider               = aws
  name                   = "${var.project_name}-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  provider               = aws
  name                   = "${var.project_name}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}
