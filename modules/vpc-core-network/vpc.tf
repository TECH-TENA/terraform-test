resource "aws_vpc" "main" {
  cidr_block           = var.config.vpc_cidr
  enable_dns_support   = var.config.enable_dns_support
  enable_dns_hostnames = var.config.enable_dns_hostnames

  tags = merge(var.tags, {
    Name = format("%s-%s-vpc", var.tags["environment"], var.tags["project"])
    },
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.config.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.config.vpc_cidr, 8, count.index)
  availability_zone       = element(var.config.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                              = format("%s-%s-public-subnet-${count.index + 1}-${element(var.config.availability_zones, count.index)}", var.tags["environment"], var.tags["project"])
    "kubernetes.io/role/elb"                          = "1"
    "kubernetes.io/cluster/${var.config.control_plane_name}" = "shared"
    },
  )
}

resource "aws_subnet" "private" {
  count             = length(var.config.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.config.vpc_cidr, 8, count.index + length(var.config.availability_zones))
  availability_zone = element(var.config.availability_zones, count.index)

  tags = merge(var.tags, {
    Name                                              = format("%s-%s-private-subnet-${count.index + 1}-${element(var.config.availability_zones, count.index)}", var.tags["environment"], var.tags["project"])
    "kubernetes.io/role/internal-elb"                 = "1"
    "kubernetes.io/cluster/${var.config.control_plane_name}" = "shared"
    },
  )
}