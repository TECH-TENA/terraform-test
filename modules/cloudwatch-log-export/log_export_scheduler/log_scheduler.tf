# provider "aws" {
#   region = var.region
# }

locals {
  lambda_name    = format("%s-%s-%s-log-export-scheduler", var.environment, var.project, var.aws_account)
  role_name      = format("%s-%s-%s-lambda-scheduler-role", var.environment, var.project, var.aws_account)
  log_bucket     = format("%s-%s-%s-log-export", var.environment, var.project, var.aws_account)
  log_group_name = var.log_group_name
}

resource "aws_iam_role" "lambda_exec_role" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.lambda_name}-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::${local.log_bucket}/*"
      }
    ]
  })
}

resource "aws_lambda_function" "log_export_lambda" {
  function_name    = local.lambda_name
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "export_logs.handler"
  runtime          = "python3.12"
  filename         = "${path.module}/lambda_function_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function_payload.zip")
  tags             = var.tags
}

resource "aws_cloudwatch_event_rule" "scheduler" {
  name                = "${local.lambda_name}-schedule"
  schedule_expression = var.schedule
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.scheduler.name
  target_id = "sendToLambda"
  arn       = aws_lambda_function.log_export_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_export_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduler.arn
}
