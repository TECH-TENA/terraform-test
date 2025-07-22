resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, {
    Name = format("%s-%s-public-route-table", var.tags["environment"], var.tags["project"])
    }
  )
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.config.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  count  = length(var.config.availability_zones)
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s-private-route-table", var.tags["environment"], var.tags["project"])
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = length(var.config.availability_zones)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
