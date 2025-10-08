resource "aws_vpc" "oaklab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "vpc-${var.region}-oaklab" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.oaklab.id
  tags   = merge(var.tags, { Name = "igw-${var.region}-oaklab" })
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.oaklab.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "subnet-public-${each.key}" })
}

resource "aws_route_table" "public" {
  for_each = var.public_subnets
  vpc_id   = aws_vpc.oaklab.id
  tags     = merge(var.tags, { Name = "rt-public-${each.key}" })
}

resource "aws_route" "public_default" {
  for_each               = var.public_subnets
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_subnet" "private" {
  for_each                = var.private_subnets
  vpc_id                  = aws_vpc.oaklab.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "subnet-private-${each.key}" })
}

resource "aws_route_table" "private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.oaklab.id
  tags     = merge(var.tags, { Name = "rt-private-${each.key}" })
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

/* Optional NAT per-AZ (default disabled) */
resource "aws_eip" "nat" {
  for_each = { for k, v in var.public_subnets : k => v if try(v.create_nat_gateway, false) }
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "eip-nat-${each.key}" })
}
#condition if create nat gateway or not
resource "aws_nat_gateway" "nat" {
  for_each      = { for k, v in var.public_subnets : k => v if try(v.create_nat_gateway, false) }
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags          = merge(var.tags, { Name = "nat-${each.key}" })
  depends_on    = [aws_internet_gateway.igw]
}

#condition if create nat gateway or not
resource "aws_route" "private_default_via_nat" {
  for_each               = { for k, v in var.private_subnets : k => v if try(var.public_subnets[k].create_nat_gateway, false) }
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = var.destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}
