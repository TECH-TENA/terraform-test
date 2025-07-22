### Event rule 
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "${var.config.lambda_function_name}-schedule"
  description         = "Trigger ${var.config.lambda_function_name} on schedule"
  schedule_expression = var.config.lambda_run_schedule
  tags                = var.tags
}

