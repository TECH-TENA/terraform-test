locals {
  gateway_endpoints = {
    s3       = "com.amazonaws.${var.region}.s3"
    dynamodb = "com.amazonaws.${var.region}.dynamodb"
  }
}

resource "aws_vpc_endpoint" "gateways" {
  for_each          = local.gateway_endpoints
  vpc_id            = aws_vpc.main.id
  service_name      = each.value
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]

  tags = merge(
    var.tags,
    {
      name = "${var.tags["environment"]}-${var.tags["project"]}-${each.key}"
    }
  )
}