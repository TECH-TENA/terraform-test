terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ami_cleanup_lambda" {
  name = "${var.lambda_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "ami_cleanup_policy" {
  name = "${var.lambda_name}-policy"
  role = aws_iam_role.ami_cleanup_lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots",
          "ec2:DeregisterImage",
          "ec2:DeleteSnapshot"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow",
        Action = ["ssm:PutParameter"],
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/ami-cleanup/last-run"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/scripts"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "ami_cleanup" {
  function_name    = var.lambda_name
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.ami_cleanup_lambda.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 300
  memory_size      = 128

  layers = var.lambda_layers

  environment {
    variables = {
      AMI_TAG_KEY            = var.ami_tag_key
      AMI_TAG_VALUE_PREFIX   = var.ami_tag_value_prefix
      SNS_TOPIC_ARN          = var.sns_topic_arn
      MATTERMOST_WEBHOOK_URL = var.mattermost_webhook_url
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.lambda_name}-schedule"
  schedule_expression = var.cleanup_schedule
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "ami-cleanup"
  arn       = aws_lambda_function.ami_cleanup.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ami_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 30
  tags              = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sns_topic" "ami_cleanup_notifications" {
  name = "ami-cleanup-notifications"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each = toset(["your-email@example.com"])  # Replace with your actual emails or pass as var
  topic_arn = aws_sns_topic.ami_cleanup_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}
