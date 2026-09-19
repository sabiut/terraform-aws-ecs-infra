output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.frontend_http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener, or null when no certificate is configured"
  value       = one(aws_lb_listener.frontend_https[*].arn)
}

# Frontend Target Groups
output "frontend_blue_target_group_arn" {
  description = "ARN of the frontend blue target group"
  value       = aws_lb_target_group.frontend_blue.arn
}

output "frontend_green_target_group_arn" {
  description = "ARN of the frontend green target group"
  value       = aws_lb_target_group.frontend_green.arn
}

output "frontend_blue_target_group_name" {
  description = "Name of the frontend blue target group"
  value       = aws_lb_target_group.frontend_blue.name
}

output "frontend_green_target_group_name" {
  description = "Name of the frontend green target group"
  value       = aws_lb_target_group.frontend_green.name
}

# Backend Target Groups
output "backend_blue_target_group_arn" {
  description = "ARN of the backend blue target group"
  value       = aws_lb_target_group.backend_blue.arn
}

output "backend_green_target_group_arn" {
  description = "ARN of the backend green target group"
  value       = aws_lb_target_group.backend_green.arn
}

output "backend_blue_target_group_name" {
  description = "Name of the backend blue target group"
  value       = aws_lb_target_group.backend_blue.name
}

output "backend_green_target_group_name" {
  description = "Name of the backend green target group"
  value       = aws_lb_target_group.backend_green.name
}

# Listener Rule ARNs for backend
output "backend_listener_rule_arn" {
  description = "ARN of the backend listener rule on the HTTP listener"
  value       = aws_lb_listener_rule.backend_api.arn
}

output "backend_https_listener_rule_arn" {
  description = "ARN of the backend listener rule on the HTTPS listener, or null when no certificate is configured"
  value       = one(aws_lb_listener_rule.backend_api_https[*].arn)
}

output "test_listener_arn" {
  description = "ARN of the test listener that fronts the inactive colour"
  value       = aws_lb_listener.test.arn
}

output "backend_test_listener_rule_arn" {
  description = "ARN of the backend listener rule on the test listener"
  value       = aws_lb_listener_rule.backend_api_test.arn
}
