output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.ami_cleanup.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_lambda_function.ami_cleanup.arn
}

output "cloudwatch_event_rule_name" {
  description = "Name of the CloudWatch Event Rule triggering the Lambda"
  value       = aws_cloudwatch_event_rule.schedule.name
}

output "ami_cleanup_lambda_arn" {
  value = aws_lambda_function.ami_cleanup.arn
}
