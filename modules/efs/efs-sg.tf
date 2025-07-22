# 1.Ask the team using the EFS to tag EC2s meant to mount it:
data "aws_instances" "efs_clients" {
  filter {
    name   = "tag:EFS"
    values = ["true"]
  }
}

# 2.Get detailed info for each EC2
data "aws_instance" "clients" {
  for_each = toset(data.aws_instances.efs_clients.ids)
  instance_id = each.key
}

# 3.Extract and deduplicate SG IDs
locals {
  ec2_sg_ids = distinct(flatten([
    for inst in data.aws_instance.clients :
    inst.vpc_security_group_ids
  ]))
}

# 4.Create the EFS security group
resource "aws_security_group" "efs_sg" {
  name        = "${var.efs_config.name}-efs-sg"
  vpc_id      = var.efs_config.vpc_id
  description = "EFS SG allowing NFS access from tagged EC2s"

  dynamic "ingress" {
    for_each = local.ec2_sg_ids
    content {
      from_port       = 2049
      to_port         = 2049
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "Allow NFS from EC2 SG ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.efs_config.name}-efs-sg"
  }
}




