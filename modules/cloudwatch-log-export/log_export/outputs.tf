output "log_bucket_name" {
  value = local.log_bucket_name
}

output "log_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}

output "cloudtrail_name" {
  value = aws_cloudtrail.main.name
}

output "cloudwatch_log_group_lambda" {
  value = aws_cloudwatch_log_group.lambda.name
}

output "cloudwatch_log_group_system" {
  value = aws_cloudwatch_log_group.cloudtrail.name
}
