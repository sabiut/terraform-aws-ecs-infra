resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "frontend" {
  name_prefix = "${var.project_name}-${var.environment}-frontend-"
  description = "Security group for Frontend ECS service"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "backend" {
  name_prefix = "${var.project_name}-${var.environment}-backend-"
  description = "Security group for Backend ECS service"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Security Group Rules
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from Internet"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from Internet"
}

resource "aws_security_group_rule" "alb_egress_frontend" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
  security_group_id        = aws_security_group.alb.id
  description              = "To Frontend ECS"
}

# The test listener fronts the inactive colour, which may be running an
# unreleased build, so it is not open to the internet by default. With no
# CIDR blocks there is no ingress rule at all; the listener still exists so
# the inactive target groups stay attached and health checked.
resource "aws_security_group_rule" "alb_ingress_test" {
  count = length(var.test_listener_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.test_listener_port
  to_port           = var.test_listener_port
  protocol          = "tcp"
  cidr_blocks       = var.test_listener_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Blue/green test listener"
}

# The listener routes /api/*, /health/* and /admin/* straight to the backend,
# so the ALB must be able to reach backend tasks for both traffic and health
# checks.
resource "aws_security_group_rule" "alb_egress_backend" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = aws_security_group.alb.id
  description              = "To Backend ECS"
}

# Frontend Security Group Rules
resource "aws_security_group_rule" "frontend_ingress_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.frontend.id
  description              = "From ALB"
}

resource "aws_security_group_rule" "frontend_egress_backend" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = aws_security_group.frontend.id
  description              = "To Backend ECS"
}

resource "aws_security_group_rule" "frontend_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "HTTPS outbound for package downloads"
}

# Backend Security Group Rules
resource "aws_security_group_rule" "backend_ingress_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.backend.id
  description              = "From ALB"
}

resource "aws_security_group_rule" "backend_ingress_frontend" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
  security_group_id        = aws_security_group.backend.id
  description              = "From Frontend ECS"
}

resource "aws_security_group_rule" "backend_egress_rds" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  security_group_id        = aws_security_group.backend.id
  description              = "To RDS MySQL"
}

resource "aws_security_group_rule" "backend_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
  description       = "HTTPS outbound for package downloads"
}

# RDS Security Group Rules
resource "aws_security_group_rule" "rds_ingress_backend" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = aws_security_group.rds.id
  description              = "MySQL from Backend ECS"
}