output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

# Blue/Green Service Names
output "frontend_blue_service_name" {
  description = "Name of the frontend blue ECS service"
  value       = aws_ecs_service.frontend_blue.name
}

output "frontend_green_service_name" {
  description = "Name of the frontend green ECS service"
  value       = aws_ecs_service.frontend_green.name
}

output "backend_blue_service_name" {
  description = "Name of the backend blue ECS service"
  value       = aws_ecs_service.backend_blue.name
}

output "backend_green_service_name" {
  description = "Name of the backend green ECS service"
  value       = aws_ecs_service.backend_green.name
}

# Legacy outputs for backward compatibility
output "frontend_service_name" {
  description = "Name of the frontend ECS service (blue active by default)"
  value       = aws_ecs_service.frontend_blue.name
}

output "backend_service_name" {
  description = "Name of the backend ECS service (blue active by default)"
  value       = aws_ecs_service.backend_blue.name
}

output "frontend_task_definition_arn" {
  description = "ARN of the frontend task definition"
  value       = aws_ecs_task_definition.frontend.arn
}

output "backend_task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend.arn
}