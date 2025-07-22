output "vpc_id" {
  description = "The ID of the VPC created"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = module.vpc.private_route_table_id
}


output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "network_acl_id" {
  description = "The ID of the open network ACL"
  value       = module.vpc.network_acl_id
}

output "public_nacl_association_ids" {
  description = "List of association IDs for public subnet NACLs"
  value       = module.vpc.public_nacl_association_ids
}

output "private_nacl_association_ids" {
  description = "List of association IDs for private subnet NACLs"
  value       = module.vpc.private_nacl_association_ids
}

output "gateway_endpoint_ids" {
  description = "Map of Gateway endpoint IDs (e.g., s3, dynamodb)"
  value       = module.vpc.gateway_endpoint_ids
}

output "gateway_endpoint_arns" {
  description = "Map of Gateway endpoint ARNs (e.g., s3, dynamodb)"
  value       = module.vpc.gateway_endpoint_arns
}
