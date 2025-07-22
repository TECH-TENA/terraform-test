resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.config.lambda_function_name}"
  retention_in_days = var.config.log_retention_days

  tags = var.tags
}
