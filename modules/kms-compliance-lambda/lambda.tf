data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "kms_rotation" {
  function_name = var.config.lambda_function_name
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.config.runtime
  timeout       = var.config.timeout

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.config.dynamodb_table_name
      MM_WEBHOOK_URL      = var.config.mattermost_webhook_url
    }
  }

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  tags             = var.tags
}



