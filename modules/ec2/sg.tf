resource "aws_security_group" "sg" {
  description = "Allow controlled inbound traffic"
  vpc_id      = var.config.vpc_id
  name        = format("%s-%s-ec2-sg", var.tags["environment"], var.tags["project"])
  tags        = var.tags
}

# Allow only VPN IP to access specified TCP ports
resource "aws_security_group_rule" "allowed_tcp_from_vpn" {
  for_each          = { for idx, port in var.config.allowed_ports : idx => port }
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = [var.config.allowed_ips.vpn]  # Assumes "vpn" exists
  security_group_id = aws_security_group.sg.id
}

# Allow ICMP (ping) from anywhere
resource "aws_security_group_rule" "allow_icmp" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

# Allow all traffic from explicitly allowed IPs (excluding vpn if already handled above)
resource "aws_security_group_rule" "allowed_ips" {
  for_each          = { for k, v in var.config.allowed_ips : k => v if k != "vpn" }
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [each.value]
  description       = each.key
  security_group_id = aws_security_group.sg.id
}
