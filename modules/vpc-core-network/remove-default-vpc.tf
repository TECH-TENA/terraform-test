data "aws_vpc" "default" {
  count   = var.delete_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.delete_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_internet_gateway" "default" {
  count = var.delete_default_vpc ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_route_tables" "default" {
  count = var.delete_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_security_groups" "default" {
  count = var.delete_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_security_group" "default_sg" {
  count = var.delete_default_vpc ? 1 : 0
  filter {
    name   = "group-name"
    values = ["default"]
  }
  vpc_id = data.aws_vpc.default[0].id
}

resource "null_resource" "delete_subnets" {
  count = var.delete_default_vpc ? length(data.aws_subnets.default[0].ids) : 0

  provisioner "local-exec" {
    command = "aws ec2 delete-subnet --subnet-id ${data.aws_subnets.default[0].ids[count.index]} --region ${var.region} || echo 'Subnet already deleted or does not exist.'"
  }
}

resource "null_resource" "delete_igw" {
  count = var.delete_default_vpc ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      IGW_ID=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${data.aws_vpc.default[0].id} --region ${var.region} --query 'InternetGateways[0].InternetGatewayId' --output text)
      if [ "$IGW_ID" != "None" ]; then
        echo "Detaching and deleting IGW: $IGW_ID"
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id ${data.aws_vpc.default[0].id} --region ${var.region}
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region ${var.region}
      else
        echo "No Internet Gateway found or already deleted."
      fi
    EOT
  }
}

resource "null_resource" "delete_route_tables" {
  count = var.delete_default_vpc ? length([for rt in data.aws_route_tables.default[0].ids : rt if rt != data.aws_vpc.default[0].main_route_table_id]) : 0

  provisioner "local-exec" {
    command = "aws ec2 delete-route-table --route-table-id ${[for rt in data.aws_route_tables.default[0].ids : rt if rt != data.aws_vpc.default[0].main_route_table_id][count.index]} --region ${var.region} || echo 'Route Table already deleted or does not exist.'"
  }
}

resource "null_resource" "delete_security_groups" {
  count = var.delete_default_vpc ? length([for sg in data.aws_security_groups.default[0].ids : sg if sg != data.aws_security_group.default_sg[0].id]) : 0

  provisioner "local-exec" {
    command = "aws ec2 delete-security-group --group-id ${[for sg in data.aws_security_groups.default[0].ids : sg if sg != data.aws_security_group.default_sg[0].id][count.index]} --region ${var.region} || echo 'Security group already deleted or does not exist.'"
  }
}

resource "null_resource" "delete_vpc" {
  count = var.delete_default_vpc ? 1 : 0

  provisioner "local-exec" {
    command = "aws ec2 delete-vpc --vpc-id ${data.aws_vpc.default[0].id} --region ${var.region} || echo 'VPC already deleted or does not exist.'"
  }
}
