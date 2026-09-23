output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.networking.database_subnet_ids
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
  description = "ARN of the RDS-managed Secrets Manager secret holding the database credentials"
  value       = module.rds.db_secret_arn
}

# Blue/green deployment handles. The deployment pipeline uses these to find
# the inactive colour, register a new task definition, and switch traffic.
output "http_listener_arn" {
  description = "ARN of the forwarding HTTP listener, or null when a certificate is configured and port 80 only redirects to HTTPS"
  value       = module.alb.listener_arn
}

output "https_listener_arn" {
  description = "ARN of the ALB HTTPS listener, or null when no certificate is configured"
  value       = module.alb.https_listener_arn
}

output "backend_listener_rule_arn" {
  description = "ARN of the HTTP listener rule that selects the active backend colour, or null when port 80 only redirects"
  value       = module.alb.backend_listener_rule_arn
}

output "backend_https_listener_rule_arn" {
  description = "ARN of the HTTPS listener rule that selects the active backend colour, or null"
  value       = module.alb.backend_https_listener_rule_arn
}

output "test_listener_arn" {
  description = "ARN of the test listener that fronts the inactive colour"
  value       = module.alb.test_listener_arn
}

output "backend_test_listener_rule_arn" {
  description = "ARN of the backend rule on the test listener"
  value       = module.alb.backend_test_listener_rule_arn
}

output "test_url" {
  description = "URL of the inactive colour for pre-switch validation, reachable only from test_listener_cidr_blocks"
  value       = "http://${module.alb.alb_dns_name}:${var.test_listener_port}"
}

output "frontend_target_group_arns" {
  description = "Frontend target group ARNs by colour"
  value = {
    blue  = module.alb.frontend_blue_target_group_arn
    green = module.alb.frontend_green_target_group_arn
  }
}

output "backend_target_group_arns" {
  description = "Backend target group ARNs by colour"
  value = {
    blue  = module.alb.backend_blue_target_group_arn
    green = module.alb.backend_green_target_group_arn
  }
}

output "frontend_service_names" {
  description = "Frontend ECS service names by colour"
  value = {
    blue  = module.ecs.frontend_blue_service_name
    green = module.ecs.frontend_green_service_name
  }
}

output "backend_service_names" {
  description = "Backend ECS service names by colour"
  value = {
    blue  = module.ecs.backend_blue_service_name
    green = module.ecs.backend_green_service_name
  }
}

output "alarm_sns_topic_arn" {
  description = "ARN of the alarm notification topic, or null when alarm_email is not set"
  value       = module.monitoring.sns_topic_arn
}

output "alarm_names" {
  description = "CloudWatch alarms created for this environment"
  value       = module.monitoring.alarm_names
}
