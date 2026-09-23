data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM policy for accessing Secrets Manager
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Policy to allow ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.db_secret_arn
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-secrets-access"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  })
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-${var.environment}-frontend"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend-logs"
  })
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-${var.environment}-backend"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-logs"
  })
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    merge({
      name  = "frontend"
      image = var.frontend_image
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        {
          name  = "PORT"
          value = "8080"
        }
      ]
    }, length(var.frontend_command) > 0 ? { command = var.frontend_command } : {})
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend-task"
  })
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    merge({
      name  = "backend"
      image = var.backend_image
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        {
          name  = "PORT"
          value = "8080"
        },
        {
          name  = "DB_HOST"
          value = var.rds_endpoint
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        }
      ]
      # The RDS-managed secret is a JSON document with "username" and
      # "password" keys; the ":key::" suffix injects a single key. ECS reads
      # the secret only at task start; see secret_rotation.tf for how tasks
      # pick up a rotated password.
      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ]
    }, length(var.backend_command) > 0 ? { command = var.backend_command } : {})
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-task"
  })
}

# Blue/Green Frontend Services. Blue is the initial active colour.
resource "aws_ecs_service" "frontend_blue" {
  name            = "${var.project_name}-${var.environment}-frontend-blue"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  # Stop a rollout whose tasks keep failing and roll back to the last
  # healthy task definition instead of looping until someone notices.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [var.frontend_security_group_id]
    subnets          = var.public_subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.frontend_blue_target_group_arn
    container_name   = "frontend"
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  # The deployment pipeline registers new task definition revisions and
  # scales colours up and down during a blue/green switch. Terraform sets the
  # initial state only and must not revert those changes on the next apply.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-frontend-blue-service"
    Color = "blue"
  })
}

resource "aws_ecs_service" "frontend_green" {
  name            = "${var.project_name}-${var.environment}-frontend-green"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 0 # Inactive colour; the pipeline scales it up before a switch
  launch_type     = "FARGATE"

  # Stop a rollout whose tasks keep failing and roll back to the last
  # healthy task definition instead of looping until someone notices.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [var.frontend_security_group_id]
    subnets          = var.public_subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.frontend_green_target_group_arn
    container_name   = "frontend"
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  # The deployment pipeline registers new task definition revisions and
  # scales colours up and down during a blue/green switch. Terraform sets the
  # initial state only and must not revert those changes on the next apply.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-frontend-green-service"
    Color = "green"
  })
}

# Blue/Green Backend Services
resource "aws_ecs_service" "backend_blue" {
  name            = "${var.project_name}-${var.environment}-backend-blue"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  # Stop a rollout whose tasks keep failing and roll back to the last
  # healthy task definition instead of looping until someone notices.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [var.backend_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_blue_target_group_arn
    container_name   = "backend"
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  # The deployment pipeline registers new task definition revisions and
  # scales colours up and down during a blue/green switch. Terraform sets the
  # initial state only and must not revert those changes on the next apply.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-backend-blue-service"
    Color = "blue"
  })
}

resource "aws_ecs_service" "backend_green" {
  name            = "${var.project_name}-${var.environment}-backend-green"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 0 # Inactive colour; the pipeline scales it up before a switch
  launch_type     = "FARGATE"

  # Stop a rollout whose tasks keep failing and roll back to the last
  # healthy task definition instead of looping until someone notices.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [var.backend_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_green_target_group_arn
    container_name   = "backend"
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  # The deployment pipeline registers new task definition revisions and
  # scales colours up and down during a blue/green switch. Terraform sets the
  # initial state only and must not revert those changes on the next apply.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = merge(var.tags, {
    Name  = "${var.project_name}-${var.environment}-backend-green-service"
    Color = "green"
  })
}

data "aws_region" "current" {}