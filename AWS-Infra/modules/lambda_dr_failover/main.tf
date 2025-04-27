resource "aws_lambda_function" "dr_failover" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.lambda_function_name
  role          = var.lambda_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  environment {
    variables = {
      PRIMARY_ASG_NAME = var.primary_asg_name
      DR_ASG_NAME      = var.dr_asg_name
      REGION           = var.primary_region
      DR_REGION        = var.dr_region
      SNS_TOPIC_ARN    = var.sns_topic_arn
    }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.cloudwatch_alarm_arn
}

resource "aws_cloudwatch_event_rule" "dr_failover_rule" {
  name        = "${var.lambda_function_name}-rule"
  description = "Trigger Lambda when primary region health alarm is triggered"
  event_pattern = jsonencode({
    "source" : ["aws.cloudwatch"],
    "detail-type" : ["CloudWatch Alarm State Change"],
    "detail" : {
      "state" : ["ALARM"],
      "alarmName" : [var.cloudwatch_alarm_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "dr_failover_target" {
  rule      = aws_cloudwatch_event_rule.dr_failover_rule.name
  target_id = "dr-failover-lambda"
  arn       = aws_lambda_function.dr_failover.arn
}
