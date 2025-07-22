output "vpc_id" {
  description = "The ID of the VPC created"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "network_acl_id" {
  description = "The ID of the open network ACL"
  value       = aws_network_acl.open.id
}

output "public_nacl_association_ids" {
  description = "List of association IDs for public subnet NACLs"
  value       = aws_network_acl_association.public[*].id
}

output "private_nacl_association_ids" {
  description = "List of association IDs for private subnet NACLs"
  value       = aws_network_acl_association.private[*].id
}

output "gateway_endpoint_ids" {
  description = "Map of Gateway endpoint IDs"
  value = {
    for k, ep in aws_vpc_endpoint.gateways : k => ep.id
  }
}

output "gateway_endpoint_arns" {
  description = "Map of Gateway endpoint ARNs"
  value = {
    for k, ep in aws_vpc_endpoint.gateways : k => ep.arn
  }
}
