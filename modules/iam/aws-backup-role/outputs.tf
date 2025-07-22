output "aws_backup_service_role_arn" {
  description = "ARN of the AWS Backup service role"
  value       = aws_iam_role.aws_backup_service_role.arn
}
