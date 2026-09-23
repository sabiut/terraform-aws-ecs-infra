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

output "alb_arn_suffix" {
  description = "ARN suffix of the load balancer, for CloudWatch metric dimensions"
  value       = aws_lb.main.arn_suffix
}

output "listener_arn" {
  description = "ARN of the forwarding HTTP listener, or null when a certificate is configured and port 80 only redirects"
  value       = var.certificate_arn == "" ? aws_lb_listener.http.arn : null
}

output "http_redirect_listener_arn" {
  description = "ARN of the HTTP to HTTPS redirect listener, or null when no certificate is configured"
  value       = var.certificate_arn != "" ? aws_lb_listener.http.arn : null
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener, or null when no certificate is configured"
  value       = one(aws_lb_listener.frontend_https[*].arn)
}

# Frontend Target Groups
output "frontend_blue_target_group_arn" {
  description = "ARN of the frontend blue target group"
  value       = aws_lb_target_group.frontend_blue.arn

  # ECS refuses to create a service whose target group is not attached to a
  # load balancer, and a target group ARN exists before any listener refers
  # to it. Consumers of these outputs therefore wait for every listener and
  # rule, so the services are created only once the attachment exists.
  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.frontend_https,
    aws_lb_listener.test,
    aws_lb_listener_rule.backend_api,
    aws_lb_listener_rule.backend_api_https,
    aws_lb_listener_rule.backend_api_test,
  ]
}

output "frontend_green_target_group_arn" {
  description = "ARN of the frontend green target group"
  value       = aws_lb_target_group.frontend_green.arn

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.frontend_https,
    aws_lb_listener.test,
    aws_lb_listener_rule.backend_api,
    aws_lb_listener_rule.backend_api_https,
    aws_lb_listener_rule.backend_api_test,
  ]
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

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.frontend_https,
    aws_lb_listener.test,
    aws_lb_listener_rule.backend_api,
    aws_lb_listener_rule.backend_api_https,
    aws_lb_listener_rule.backend_api_test,
  ]
}

output "backend_green_target_group_arn" {
  description = "ARN of the backend green target group"
  value       = aws_lb_target_group.backend_green.arn

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.frontend_https,
    aws_lb_listener.test,
    aws_lb_listener_rule.backend_api,
    aws_lb_listener_rule.backend_api_https,
    aws_lb_listener_rule.backend_api_test,
  ]
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
  description = "ARN of the backend listener rule on the HTTP listener, or null when port 80 only redirects"
  value       = one(aws_lb_listener_rule.backend_api[*].arn)
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

output "target_group_arn_suffixes" {
  description = "ARN suffixes of the target groups by tier and colour, for CloudWatch metric dimensions"
  value = {
    frontend_blue  = aws_lb_target_group.frontend_blue.arn_suffix
    frontend_green = aws_lb_target_group.frontend_green.arn_suffix
    backend_blue   = aws_lb_target_group.backend_blue.arn_suffix
    backend_green  = aws_lb_target_group.backend_green.arn_suffix
  }
}
