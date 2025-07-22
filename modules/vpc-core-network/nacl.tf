resource "aws_network_acl" "open" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = format("%s-%s-nacl", var.tags["environment"], var.tags["project"])
    },
  )
}

resource "aws_network_acl_rule" "open_inbound" {
  count = length(var.config.open_inbound_acl_rules)

  network_acl_id = aws_network_acl.open.id
  egress         = false
  rule_number    = var.config.open_inbound_acl_rules[count.index]["rule_number"]
  rule_action    = var.config.open_inbound_acl_rules[count.index]["rule_action"]
  from_port      = lookup(var.config.open_inbound_acl_rules[count.index], "from_port", 0)
  to_port        = lookup(var.config.open_inbound_acl_rules[count.index], "to_port", 0)
  icmp_code      = lookup(var.config.open_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type      = lookup(var.config.open_inbound_acl_rules[count.index], "icmp_type", null)
  protocol       = var.config.open_inbound_acl_rules[count.index]["protocol"]
  cidr_block     = lookup(var.config.open_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.config.open_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "open_outbound" {
  count = length(var.config.open_outbound_acl_rules)

  network_acl_id = aws_network_acl.open.id
  egress         = true
  rule_number    = var.config.open_outbound_acl_rules[count.index]["rule_number"]
  rule_action    = var.config.open_outbound_acl_rules[count.index]["rule_action"]
  from_port      = lookup(var.config.open_outbound_acl_rules[count.index], "from_port", 0)
  to_port        = lookup(var.config.open_outbound_acl_rules[count.index], "to_port", 0)
  icmp_code      = lookup(var.config.open_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type      = lookup(var.config.open_outbound_acl_rules[count.index], "icmp_type", null)
  protocol       = var.config.open_outbound_acl_rules[count.index]["protocol"]
  cidr_block     = lookup(var.config.open_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.config.open_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}


# Associate NACL with subnets (public and/or private)
resource "aws_network_acl_association" "public" {
  count          = length(var.config.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  network_acl_id = aws_network_acl.open.id
}

resource "aws_network_acl_association" "private" {
  count          = length(var.config.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  network_acl_id = aws_network_acl.open.id
}
