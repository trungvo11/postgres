#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "eks-cluster" {
  cidr_block = "10.0.0.0/16"

  tags = tomap({
    "Name" = "terraform-eks-cluster",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

resource "aws_subnet" "eks-cluster-subnet" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eks-cluster.id

  tags = tomap({
    "Name" = "eks-cluster-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

resource "aws_internet_gateway" "eks-cluster-ig" {
  vpc_id = aws_vpc.eks-cluster.id

  tags = {
    Name = "eks-cluster-ig"
  }
}

resource "aws_route_table" "eks-cluster-crt" {
  vpc_id = aws_vpc.eks-cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-cluster-ig.id
  }
}

resource "aws_route_table_association" "eks-cluster-route-table" {
  count = 2

  subnet_id      = aws_subnet.eks-cluster-subnet.*.id[count.index]
  route_table_id = aws_route_table.eks-cluster-crt.id
}