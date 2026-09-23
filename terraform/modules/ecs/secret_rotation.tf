# RDS rotates the master password in Secrets Manager every seven days by
# default, but ECS injects secrets only when a task starts, so running backend
# tasks would keep the old password and fail to open new database connections
# once it stops working. When Secrets Manager moves the AWSCURRENT label on
# the database secret, EventBridge starts a Step Functions state machine that
# forces a new deployment of both backend services. The rolling deployment
# starts tasks with the new password before stopping the old ones; the
# inactive colour has no tasks, so its deployment is a no-op.
#
# UpdateService only queues the deployment, so the state machine then polls
# DescribeServices until the service has a single deployment that reports
# COMPLETED, which means every old task is gone. If ECS rolls the deployment
# back its rollout state is FAILED and the execution fails; an execution
# that has not settled within an hour times out. Both raise the
# db-secret-redeploy-failed alarm. A rollback that does complete still
# counts as success: its tasks were also started after the rotation.
#
# New connections from the old tasks fail between the password change and
# the new tasks becoming healthy, typically a few minutes. An application
# that must not see that window should read the secret itself on connection
# failure rather than rely on the injected environment variable.

locals {
  backend_services = {
    blue  = aws_ecs_service.backend_blue
    green = aws_ecs_service.backend_green
  }

  # ECS API calls are retried on throttling and transient errors.
  redeploy_retry = [
    {
      ErrorEquals     = ["States.ALL"]
      IntervalSeconds = 5
      MaxAttempts     = 3
      BackoffRate     = 2
    }
  ]
}

resource "aws_iam_role" "db_secret_redeploy" {
  name = "${var.project_name}-${var.environment}-db-secret-redeploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-secret-redeploy"
  })
}

resource "aws_iam_role_policy" "db_secret_redeploy" {
  name = "redeploy-backend-services"
  role = aws_iam_role.db_secret_redeploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
        Resource = [for s in local.backend_services : s.id]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "db_secret_redeploy" {
  name     = "${var.project_name}-${var.environment}-db-secret-redeploy"
  role_arn = aws_iam_role.db_secret_redeploy.arn

  definition = jsonencode({
    Comment        = "Force a new deployment of the backend services so tasks start with the rotated database password, and wait for it to finish"
    TimeoutSeconds = 3600
    StartAt        = "ListBackendServices"
    States = {
      ListBackendServices = {
        Type = "Pass"
        Parameters = {
          services = [for s in local.backend_services : { name = s.name }]
        }
        Next = "RedeployEach"
      }
      RedeployEach = {
        Type           = "Map"
        ItemsPath      = "$.services"
        MaxConcurrency = 2
        End            = true
        Iterator = {
          StartAt = "ForceNewDeployment"
          States = {
            ForceNewDeployment = {
              Type     = "Task"
              Resource = "arn:aws:states:::aws-sdk:ecs:updateService"
              Parameters = {
                Cluster            = aws_ecs_cluster.main.name
                "Service.$"        = "$.name"
                ForceNewDeployment = true
              }
              ResultPath = null
              Retry      = local.redeploy_retry
              Next       = "WaitForRollout"
            }
            WaitForRollout = {
              Type    = "Wait"
              Seconds = 30
              Next    = "DescribeService"
            }
            DescribeService = {
              Type     = "Task"
              Resource = "arn:aws:states:::aws-sdk:ecs:describeServices"
              Parameters = {
                Cluster      = aws_ecs_cluster.main.name
                "Services.$" = "States.Array($.name)"
              }
              # Deployments[0] is the PRIMARY deployment. Old deployments stay
              # listed while their tasks drain, so a count of one means no
              # task started before the rotation is still running.
              ResultSelector = {
                "rolloutState.$"    = "$.Services[0].Deployments[0].RolloutState"
                "deploymentCount.$" = "States.ArrayLength($.Services[0].Deployments)"
              }
              ResultPath = "$.rollout"
              Retry      = local.redeploy_retry
              Next       = "CheckRollout"
            }
            CheckRollout = {
              Type = "Choice"
              Choices = [
                {
                  Variable     = "$.rollout.rolloutState"
                  StringEquals = "FAILED"
                  Next         = "RolloutFailed"
                },
                {
                  And = [
                    {
                      Variable     = "$.rollout.rolloutState"
                      StringEquals = "COMPLETED"
                    },
                    {
                      Variable      = "$.rollout.deploymentCount"
                      NumericEquals = 1
                    }
                  ]
                  Next = "RolloutComplete"
                }
              ]
              Default = "WaitForRollout"
            }
            RolloutFailed = {
              Type  = "Fail"
              Error = "RolloutFailed"
              Cause = "ECS rolled the deployment back; backend tasks may still hold the old database password"
            }
            RolloutComplete = {
              Type = "Succeed"
            }
          }
        }
      }
    }
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-secret-redeploy"
  })
}

resource "aws_iam_role" "db_secret_rotated_events" {
  name = "${var.project_name}-${var.environment}-db-secret-rotated-events"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-secret-rotated-events"
  })
}

resource "aws_iam_role_policy" "db_secret_rotated_events" {
  name = "start-redeploy"
  role = aws_iam_role.db_secret_rotated_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = aws_sfn_state_machine.db_secret_redeploy.arn
      }
    ]
  })
}

# Secrets Manager publishes "Secret Label Updated" natively (no CloudTrail
# trail needed) whenever a staging label moves. AWSCURRENT moving to a new
# version is exactly "the active password changed", whether by scheduled
# rotation or a manual rotate-master-user-password.
resource "aws_cloudwatch_event_rule" "db_secret_rotated" {
  name        = "${var.project_name}-${var.environment}-db-secret-rotated"
  description = "Database master password rotated; redeploy backend tasks"

  event_pattern = jsonencode({
    source        = ["aws.secretsmanager"]
    "detail-type" = ["Secret Label Updated"]
    resources     = [var.db_secret_arn]
    detail = {
      labelUpdated = ["AWSCURRENT"]
    }
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-secret-rotated"
  })
}

resource "aws_cloudwatch_event_target" "db_secret_rotated" {
  rule     = aws_cloudwatch_event_rule.db_secret_rotated.name
  arn      = aws_sfn_state_machine.db_secret_redeploy.arn
  role_arn = aws_iam_role.db_secret_rotated_events.arn
}
