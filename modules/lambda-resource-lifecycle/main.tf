# Package Lambda (zip entire folder)
data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

# EC2 Lifecycle Lambda
resource "aws_lambda_function" "ec2_lifecycle" {
  function_name = format("%s-%s-ec2-lifecycle-manager", var.tags["environment"], var.tags["project"])
  role          = aws_iam_role.lambda_role.arn
  handler       = "ec2_lifecycle.ec2_lifecycle_handler" 
  runtime       = "python3.9"
  filename      = data.archive_file.lambda_function_zip.output_path
  timeout       = var.ec2_lifecycle_config.lambda_timeout_ec2

  environment {
    variables = {
      COST_THRESHOLD        = tostring(var.ec2_lifecycle_config.cost_threshold)
      MICRO_MAX_AGE_DAYS    = tostring(var.ec2_lifecycle_config.micro_max_age_days)
      DEFAULT_MAX_AGE_DAYS  = tostring(var.ec2_lifecycle_config.default_max_age_days)
      MATTERMOST_WEBHOOK_URL = var.ec2_lifecycle_config.mattermost_webhook_url
      REQUIRED_TAG_KEYS = format(
        "env=%s, owner=%s",
        var.tags["environment"],
        var.tags["owner"]
      )

    }
  }
}

resource "aws_cloudwatch_log_group" "ec2_lifecycle" {
  name              = "/aws/lambda/${aws_lambda_function.ec2_lifecycle.function_name}"
  retention_in_days = 30
  depends_on = [aws_lambda_function.ec2_lifecycle]
}

# Resource Creation Logger Lambda
resource "aws_lambda_function" "resource_logger" {
  function_name = format("%s-%s-ec2-resource-logger", var.tags["environment"], var.tags["project"])
  role          = aws_iam_role.lambda_role.arn
  handler       = "logger.resource_logger_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.lambda_function_zip.output_path
  timeout       = var.ec2_lifecycle_config.lambda_timeout_ec2
}

resource "aws_cloudwatch_log_group" "resource_logger" {
  name              = "/aws/lambda/${aws_lambda_function.resource_logger.function_name}"
  retention_in_days = 30
  depends_on = [aws_lambda_function.resource_logger]
}

# EventBridge rule for EC2 lifecycle check
resource "aws_cloudwatch_event_rule" "ec2_lifecycle_schedule" {
  name                = format("%s-%s-ec2-lifecycle-schedule", var.tags["environment"], var.tags["project"])
  schedule_expression = "cron(0 0 * * ? *)"  # Runs every day at 12 AM UTC
}

resource "aws_cloudwatch_event_target" "ec2_lifecycle_target" {
  rule      = aws_cloudwatch_event_rule.ec2_lifecycle_schedule.name
  target_id = "ec2Lambda"
  arn       = aws_lambda_function.ec2_lifecycle.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_lifecycle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_lifecycle_schedule.arn
}

# EventBridge rule for S3 bucket creation
resource "aws_cloudwatch_event_rule" "s3_create" {
  name = format("%s-%s-log-s3-creation", var.tags["environment"], var.tags["project"])
  event_pattern = jsonencode({
    source = ["aws.s3"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = ["CreateBucket"]
    }
  })
}

# EventBridge rule for SecretsManager secret creation
resource "aws_cloudwatch_event_rule" "secretsmanager_create" {
  name = format("%s-%s-log-secret-creation", var.tags["environment"], var.tags["project"])
  event_pattern = jsonencode({
    source = ["aws.secretsmanager"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = ["CreateSecret"]
    }
  })
}

# Event targets for creation logging
resource "aws_cloudwatch_event_target" "s3_target" {
  rule      = aws_cloudwatch_event_rule.s3_create.name
  target_id = "s3Logger"
  arn       = aws_lambda_function.resource_logger.arn
}

resource "aws_cloudwatch_event_target" "secrets_target" {
  rule      = aws_cloudwatch_event_rule.secretsmanager_create.name
  target_id = "secretLogger"
  arn       = aws_lambda_function.resource_logger.arn
}

# Lambda invoke permissions
resource "aws_lambda_permission" "s3_create_permission" {
  statement_id  = "AllowS3CreateLogging"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_logger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_create.arn
}

resource "aws_lambda_permission" "secret_create_permission" {
  statement_id  = "AllowSecretCreateLogging"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_logger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.secretsmanager_create.arn
}
