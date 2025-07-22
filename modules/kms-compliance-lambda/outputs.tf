output "lambda_function_name" {
  value = aws_lambda_function.kms_rotation.function_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.rotation_logs.name
}

output "iam_role_name" {
  value = aws_iam_role.lambda_execution.name
}
