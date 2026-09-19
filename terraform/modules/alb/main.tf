# ALB and target group names are limited to 32 characters, so they use the
# short project name. Everything else keeps the full project name.
resource "aws_lb" "main" {
  name               = "${var.short_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

# Blue/Green Target Groups for Frontend
resource "aws_lb_target_group" "frontend_blue" {
  name        = "${var.short_name}-${var.environment}-fe-blue"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.frontend_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    precondition {
      condition     = length("${var.short_name}-${var.environment}-fe-blue") <= 32
      error_message = "Target group name exceeds 32 characters; shorten short_name or environment."
    }
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-frontend-blue"
    Color = "blue"
  })
}

resource "aws_lb_target_group" "frontend_green" {
  name        = "${var.short_name}-${var.environment}-fe-green"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.frontend_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    precondition {
      condition     = length("${var.short_name}-${var.environment}-fe-green") <= 32
      error_message = "Target group name exceeds 32 characters; shorten short_name or environment."
    }
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-frontend-green"
    Color = "green"
  })
}

# Blue/Green Target Groups for Backend
resource "aws_lb_target_group" "backend_blue" {
  name        = "${var.short_name}-${var.environment}-be-blue"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.backend_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    precondition {
      condition     = length("${var.short_name}-${var.environment}-be-blue") <= 32
      error_message = "Target group name exceeds 32 characters; shorten short_name or environment."
    }
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-backend-blue"
    Color = "blue"
  })
}

resource "aws_lb_target_group" "backend_green" {
  name        = "${var.short_name}-${var.environment}-be-green"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.backend_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    precondition {
      condition     = length("${var.short_name}-${var.environment}-be-green") <= 32
      error_message = "Target group name exceeds 32 characters; shorten short_name or environment."
    }
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-backend-green"
    Color = "green"
  })
}

# Without a certificate, port 80 serves the application. With one, port 80
# only redirects to HTTPS (see http_redirect below). These are two resources
# rather than one conditional action because the forwarding listener ignores
# changes to its default action so the pipeline can switch colours, and that
# would also swallow a change from forward to redirect.
resource "aws_lb_listener" "frontend_http" {
  count = var.certificate_arn == "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_blue.arn
  }

  # The deployment pipeline switches traffic between the blue and green target
  # groups by rewriting this action. Terraform sets the initial target (blue)
  # and must not revert a switch on the next apply.
  lifecycle {
    ignore_changes = [default_action]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-http-listener"
  })
}

# Listener rule for backend API traffic
resource "aws_lb_listener_rule" "backend_api" {
  count = var.certificate_arn == "" ? 1 : 0

  listener_arn = aws_lb_listener.frontend_http[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_blue.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/health/*", "/admin/*"]
    }
  }

  # Switched by the deployment pipeline; see the listener above.
  lifecycle {
    ignore_changes = [action]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-rule"
  })
}

resource "aws_lb_listener" "http_redirect" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-http-redirect-listener"
  })
}

# HTTPS is only created once an ACM certificate is supplied. AWS rejects an
# HTTPS listener with no certificate, so the listener is gated on the variable.
resource "aws_lb_listener" "frontend_https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_blue.arn
  }

  # The deployment pipeline switches traffic between the blue and green target
  # groups by rewriting this action. Terraform sets the initial target (blue)
  # and must not revert a switch on the next apply.
  lifecycle {
    ignore_changes = [default_action]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-https-listener"
  })
}

resource "aws_lb_listener_rule" "backend_api_https" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.frontend_https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_blue.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/health/*", "/admin/*"]
    }
  }

  # Switched by the deployment pipeline; see the listener above.
  lifecycle {
    ignore_changes = [action]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-rule-https"
  })
}

# Test listener. It fronts the inactive colour (green initially) so that its
# target groups are attached to the load balancer, which ECS requires before
# it will create the services, and so the ALB health checks them. A release
# validates the new colour through this listener, then swaps the production
# and test listeners together.
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.test_listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_green.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-test-listener"
  })
}

resource "aws_lb_listener_rule" "backend_api_test" {
  listener_arn = aws_lb_listener.test.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_green.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/health/*", "/admin/*"]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-rule-test"
  })
}
