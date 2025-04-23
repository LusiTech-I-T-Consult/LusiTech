# Route 53 Module for Pilot Light Disaster Recovery

# Attempt to get existing hosted zone if available
data "aws_route53_zone" "selected" {
  count        = var.create_route53_records ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# Health check for the primary load balancer
resource "aws_route53_health_check" "primary" {
  count             = var.create_route53_records ? 1 : 0
  fqdn              = var.primary_lb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health.html"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-primary-health-check"
    }
  )
}

# Route 53 record with failover routing policy
# Primary region record
resource "aws_route53_record" "primary" {
  count          = var.create_route53_records ? 1 : 0
  zone_id        = data.aws_route53_zone.selected[0].zone_id
  name           = var.record_name != "" ? var.record_name : var.domain_name
  type           = "A"
  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.primary[0].id

  alias {
    name                   = var.primary_lb_dns_name
    zone_id                = var.primary_lb_zone_id
    evaluate_target_health = true
  }
}

# DR region record
resource "aws_route53_record" "dr" {
  count          = var.create_route53_records ? 1 : 0
  zone_id        = data.aws_route53_zone.selected[0].zone_id
  name           = var.record_name != "" ? var.record_name : var.domain_name
  type           = "A"
  set_identifier = "dr"
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.dr_lb_dns_name
    zone_id                = var.dr_lb_zone_id
    evaluate_target_health = true
  }
}

# DNS Records for direct access to primary and DR environments (for testing)
resource "aws_route53_record" "primary_direct" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "primary.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.primary_lb_dns_name
    zone_id                = var.primary_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dr_direct" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "dr.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.dr_lb_dns_name
    zone_id                = var.dr_lb_zone_id
    evaluate_target_health = true
  }
}
