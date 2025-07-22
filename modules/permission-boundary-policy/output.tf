output "webforx_policy_arn" {
  description = "ARN of the created WebForx permissions boundary policy"
  value       = aws_iam_policy.webforx_permissions_boundary.arn
}