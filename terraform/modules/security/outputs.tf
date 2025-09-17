output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "frontend_security_group_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.backend.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}