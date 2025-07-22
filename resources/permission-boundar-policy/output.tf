output "permissions_boundary_policy_arn" {
  value       = module.permissions_boundary.webforx_policy_arn
  description = "Permissions boundary policy ARN"
}