# output "s3_endpoint_id" {
#   description = "ID of the S3 Gateway VPC Endpoint"
#   value       = module.gateway_endpoints.s3_endpoint_id
# }

# output "dynamodb_endpoint_id" {
#   description = "ID of the DynamoDB Gateway VPC Endpoint"
#   value       = module.gateway_endpoints.dynamodb_endpoint_id
# }

output "gateway_endpoint_ids" {
  description = "Map of Gateway endpoint IDs (e.g., s3, dynamodb)"
  value       = module.gateway_endpoints.gateway_endpoint_ids
}

output "gateway_endpoint_arns" {
  description = "Map of Gateway endpoint ARNs (e.g., s3, dynamodb)"
  value       = module.gateway_endpoints.gateway_endpoint_arns
}
