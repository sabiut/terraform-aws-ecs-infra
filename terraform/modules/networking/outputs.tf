output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, one per availability zone"
  value       = aws_subnet.public[*].id
}

output "public_subnet_id" {
  description = "ID of the first public subnet (hosts the NAT gateway and frontend tasks)"
  value       = aws_subnet.public[0].id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = aws_subnet.database.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}
