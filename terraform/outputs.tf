output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.networking.private_subnet_id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = module.networking.database_subnet_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

output "frontend_security_group_id" {
  description = "ID of the frontend security group"
  value       = module.security.frontend_security_group_id
}

output "backend_security_group_id" {
  description = "ID of the backend security group"
  value       = module.security.backend_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.security.rds_security_group_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = module.rds.db_secret_arn
}

output "db_secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = module.rds.db_secret_name
}