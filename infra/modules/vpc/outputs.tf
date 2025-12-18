# VPC ID
output "vpc_id" {
  value = aws_vpc.this.id
}

# Private subnet IDs
output "private_subnets" {
  value = aws_subnet.private[*].id
}

# Public subnet ID
output "public_subnets" {
  value = aws_subnet.public[*].id
}
