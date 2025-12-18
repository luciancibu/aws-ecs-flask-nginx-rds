# 1. VPC
# 2. IGW
# 3. Public subnets
# 4. Private subnets
# 5. Elastic IP for NAT
# 6. NAT
# 7. Route tables
#   7.1 Public subnet -> IGW
#   7.2 Private subnet -> NAT
# 8. Associations
#   8.1 Public subnet -> Route table
#   8.2 Private subnet -> Route table


# 1. VPC
resource "aws_vpc" "this" {
    cidr_block           = var.cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
        tags = {
            Name = var.name
        }
}

# 2. IGW
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-igw"
  }
}

# 3. Public subnets
resource "aws_subnet" "public" {
count             = length(var.public_subnets)
vpc_id            = aws_vpc.this.id
cidr_block        = var.public_subnets[count.index]
availability_zone = var.azs[count.index]
  tags = {
    Name = "${var.name}-public-${count.index + 1}"
  }
}

# 4. Private subnets
resource "aws_subnet" "private" {
    count             = length(var.private_subnets)
    vpc_id            = aws_vpc.this.id
    cidr_block        = var.private_subnets[count.index]
    availability_zone = var.azs[count.index]
      tags = {
        Name = "${var.name}-private-${count.index + 1}"
      }

}

# 5. Elastic IP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
  Name = "${var.name}-eip"
}
}

# 6. NAT
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id   //only 1 nat

  depends_on    = [aws_internet_gateway.this]
  tags = {
    Name = "${var.name}-nat"
  }
}

# 7. Route tables
# 7.1 Public subnet -> IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name = "${var.name}-public-rt"
  }
} 
  
# 7.2 Private subnet -> NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.name}-private-rt"
  }
}

# 8. Associations
#   8.1 Public subnet -> Route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#   8.2 Private subnet -> Route table
resource "aws_route_table_association" "private"{
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

