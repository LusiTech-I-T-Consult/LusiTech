resource "aws_sns_topic" "dr_failover_notifications" {
  name = "${var.project_name}-${var.environment}-dr-failover-notifications"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.dr_failover_notifications.arn
  protocol  = "email"
  endpoint  = var.admin_email
}
