# output "s3_endpoint_id" {
#   value = aws_vpc_endpoint.gateways["s3"].id
# }

# output "dynamodb_endpoint_id" {
#   value = aws_vpc_endpoint.gateways["dynamodb"].id
# }

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
