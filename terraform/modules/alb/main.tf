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

# Port 80. Without a certificate it serves the application; with one it only
# redirects to HTTPS. This is one resource whose default action depends on the
# certificate, not two conditional resources, because AWS allows one listener
# per port and Terraform would otherwise create the new listener while the
# old one still exists and fail with DuplicateListener. Replacing a single
# resource always destroys the old listener first.
#
# The deployment pipeline rewrites the forwarding action to switch colours, so
# Terraform ignores changes to default_action. That would also swallow the
# change between forward and redirect, so the listener is replaced outright
# whenever the certificate mode flips (see http_listener_mode below).
resource "terraform_data" "http_listener_mode" {
  triggers_replace = var.certificate_arn != ""
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.certificate_arn == "" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.frontend_blue.arn
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn != "" ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  lifecycle {
    ignore_changes       = [default_action]
    replace_triggered_by = [terraform_data.http_listener_mode]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-http-listener"
  })
}

# The forwarding HTTP listener used to be aws_lb_listener.frontend_http[0].
# A deployment that already runs with a certificate has the redirect listener
# as aws_lb_listener.http_redirect[0] instead; move it by hand before
# applying, since Terraform allows only one moved block per destination:
#   terraform state mv 'module.alb.aws_lb_listener.http_redirect[0]' module.alb.aws_lb_listener.http
moved {
  from = aws_lb_listener.frontend_http[0]
  to   = aws_lb_listener.http
}

# Listener rule for backend API traffic. Only exists while port 80 forwards.
resource "aws_lb_listener_rule" "backend_api" {
  count = var.certificate_arn == "" ? 1 : 0

  listener_arn = aws_lb_listener.http.arn
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
# and test listeners together. The listener always exists, but it is only
# reachable from test_listener_cidr_blocks (see the security module), which
# is empty by default.
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
