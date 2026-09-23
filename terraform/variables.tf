variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecs-three-tier"
}

variable "short_name" {
  description = "Short project name for resources whose names AWS limits to 32 characters (ALB, target groups). Lowercase letters, digits and hyphens, at most 8 characters."
  type        = string
  default     = "e3t"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,7}$", var.short_name))
    error_message = "short_name must be 1 to 8 characters of lowercase letters, digits and hyphens, starting with a letter or digit."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the public subnets. At least two are required for the ALB; the first also hosts the private and database subnets."
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per availability zone"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.11.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per availability zone. Backend tasks are spread across all of them."
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for the database subnets, one per availability zone. RDS requires at least two."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "certificate_arn" {
  description = "ARN of an ACM certificate for the ALB HTTPS listener. Leave empty to serve HTTP only."
  type        = string
  default     = ""
}

# Container images. The defaults are a tiny HTTP server that answers 200 on
# every path on port 8080, so a fresh apply passes health checks before any
# application image exists. The deployment pipeline replaces them.
variable "frontend_image" {
  description = "Container image for the frontend task. Must listen on 8080 and answer the frontend health check path."
  type        = string
  default     = "hashicorp/http-echo:1.0.0"
}

variable "frontend_command" {
  description = "Command for the frontend container. Set to [] when frontend_image has its own entrypoint."
  type        = list(string)
  default     = ["-listen=:8080", "-text=frontend placeholder"]
}

variable "backend_image" {
  description = "Container image for the backend task. Must listen on 8080 and answer the backend health check path."
  type        = string
  default     = "hashicorp/http-echo:1.0.0"
}

variable "backend_command" {
  description = "Command for the backend container. Set to [] when backend_image has its own entrypoint."
  type        = list(string)
  default     = ["-listen=:8080", "-text=backend placeholder"]
}

variable "frontend_health_check_path" {
  description = "HTTP path the ALB probes on frontend tasks"
  type        = string
  default     = "/api/health"
}

variable "backend_health_check_path" {
  description = "HTTP path the ALB probes on backend tasks"
  type        = string
  default     = "/health/"
}

# Blue/green test listener. It fronts the inactive colour so a release can be
# validated at http://<alb-dns>:<port> before traffic is switched. The
# inactive colour may be running an unreleased build, so the listener is
# closed until CIDR blocks are given.
variable "test_listener_port" {
  description = "ALB port for the blue/green test listener"
  type        = number
  default     = 9000
}

variable "test_listener_cidr_blocks" {
  description = "CIDR blocks allowed to reach the test listener, for example office or CI egress ranges. Empty (the default) leaves the test listener unreachable from outside the VPC."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.test_listener_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "Every entry must be an IPv4 CIDR block such as 203.0.113.0/24."
  }
}

# Sizing. Defaults suit a development environment; see the README for a
# production example.
variable "frontend_cpu" {
  description = "Fargate CPU units for the frontend task (256, 512, 1024, ...)"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Fargate memory in MiB for the frontend task; must be valid for the chosen CPU"
  type        = number
  default     = 512
}

variable "backend_cpu" {
  description = "Fargate CPU units for the backend task (256, 512, 1024, ...)"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Fargate memory in MiB for the backend task; must be valid for the chosen CPU"
  type        = number
  default     = 512
}

variable "frontend_desired_count" {
  description = "Initial task count for the active frontend colour. The pipeline owns it afterwards."
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Initial task count for the active backend colour. The pipeline owns it afterwards."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch retention for container logs"
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Run RDS with a synchronous standby in a second availability zone. Roughly doubles the instance cost."
  type        = bool
  default     = false
}

# Alarms
variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications. Leave empty for alarms without notifications."
  type        = string
  default     = ""
}

variable "alarm_actions" {
  description = "Additional SNS topic ARNs to notify on alarm and recovery"
  type        = list(string)
  default     = []
}
