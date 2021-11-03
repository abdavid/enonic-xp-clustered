data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = var.network
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }

}

resource "aws_internet_gateway" "main" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_vpc.main]
}

resource "aws_route" "main" {
  route_table_id         = aws_vpc.main.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_subnet" "public0" {
  availability_zone       = "${data.aws_region.current.name}a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 3, 0)
  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name = "${var.vpc_name} public 0"
  }
}

resource "aws_subnet" "public1" {
  availability_zone       = "${data.aws_region.current.name}b"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 3, 1)
  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name = "${var.vpc_name} public 1"
  }
}

resource "aws_subnet" "public2" {
  availability_zone       = "${data.aws_region.current.name}c"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 3, 2)
  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name = "${var.vpc_name} public 2"
  }
}


