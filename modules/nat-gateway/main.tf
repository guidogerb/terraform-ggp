resource "aws_eip" "nat_eip" {
  tags = merge(local.tags, {
    Name = "${var.prepend-name}nat-eip"
  })

}

resource "aws_nat_gateway" "gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = var.public-subnet-id

  tags = merge(local.tags, {
    Name = "${var.prepend-name}gateway"
  })

}

resource "aws_route_table" "route-table" {
  vpc_id = var.vpc_id
  tags = merge(local.tags, {
    Name = "${var.prepend-name}route-table"
  })

}

resource "aws_route" "nat-gateway-route" {
  route_table_id         = aws_route_table.route-table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gateway.id
}

resource "aws_route_table_association" "route-table-association" {
  subnet_id      = var.private-subnet-id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_security_group" "nat-gateway-secuirty-group" {
  name        = "${var.prepend-name}nat-gateway-security-group"
  description = "Nat Gateway Security Group"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name = "${var.prepend-name}nat-gateway-security-group"
  })

}

# Ingress rule - inbound
resource "aws_security_group_rule" "nat_gateway_ingress_ssh" {
  security_group_id = aws_security_group.nat-gateway-secuirty-group.id

  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${var.my-ip}/32"]
}

# Egress rule - outbound
resource "aws_security_group_rule" "nat-gateway-egress" {
  security_group_id = aws_security_group.nat-gateway-secuirty-group.id

  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
}