resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
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
  name        = "${var.project_name}-${var.environment}-frontend-blue"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-frontend-blue"
    Color = "blue"
  })
}

resource "aws_lb_target_group" "frontend_green" {
  name        = "${var.project_name}-${var.environment}-frontend-green"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-frontend-green"
    Color = "green"
  })
}

# Blue/Green Target Groups for Backend
resource "aws_lb_target_group" "backend_blue" {
  name        = "${var.project_name}-${var.environment}-backend-blue"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-backend-blue"
    Color = "blue"
  })
}

resource "aws_lb_target_group" "backend_green" {
  name        = "${var.project_name}-${var.environment}-backend-green"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-backend-green"
    Color = "green"
  })
}

resource "aws_lb_listener" "frontend_http" {
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
  listener_arn = aws_lb_listener.frontend_http.arn
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
