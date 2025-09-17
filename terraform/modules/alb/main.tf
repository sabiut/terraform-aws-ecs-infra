resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = [var.public_subnet_id]

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-${var.environment}-frontend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend-tg"
  })
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-http-listener"
  })
}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "HTTPS listener configured - SSL certificate needed"
      status_code  = "200"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-https-listener"
  })
}