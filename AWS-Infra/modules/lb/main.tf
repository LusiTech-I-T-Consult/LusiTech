# Load Balancer Module for Pilot Light DR

# Security group for the load balancer
resource "aws_security_group" "lb_sg" {
  name        = "${var.project_name}-${var.environment}-lb-sg"
  description = "Security group for the load balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
      Name = "${var.project_name}-${var.environment}-lb-sg"
    }
  )
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "${var.project_name}-${var.environment}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lb"
    }
  )
}

# Target Group for ALB Using HTTPS
resource "aws_lb_target_group" "app_tg" {
  name                 = "${var.project_name}-${var.environment}-tg"
  port                 = 443
  protocol             = "HTTPS"
  vpc_id               = var.vpc_id
  deregistration_delay = 60

  health_check {
    path                = "/health.html"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-tg"
    }
  )
}

# HTTP Listener (redirect to HTTPS if certificate available, otherwise forward to target group)
# HTTP Listener : Redirect to HTTPS
# HTTP Listener: Redirect to HTTPS (only if certificate is provided)
resource "aws_lb_listener" "http_redirect" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTP Listener: Forward directly to target group (only if certificate is NOT provided)
resource "aws_lb_listener" "http_forward" {
  count             = var.certificate_arn == "" ? 1 : 0
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# HTTPS Listener: Only if certificate is provided
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# CloudWatch Alarms for the Load Balancer
resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors application load balancer 5xx error count"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.app_lb.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "high_4xx" {
  alarm_name          = "${var.project_name}-${var.environment}-high-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "This metric monitors application load balancer 4xx error count"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.app_lb.arn_suffix
  }
}
