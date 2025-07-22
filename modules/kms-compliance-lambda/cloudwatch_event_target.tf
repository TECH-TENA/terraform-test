# Event target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "Trigger${var.config.lambda_function_name}"
  arn       = aws_lambda_function.kms_rotation.arn
}