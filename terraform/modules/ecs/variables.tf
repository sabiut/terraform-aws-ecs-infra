variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets the frontend tasks are spread across"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets the backend tasks are spread across"
  type        = list(string)
}

variable "frontend_cpu" {
  description = "Fargate CPU units for the frontend task"
  type        = number
}

variable "frontend_memory" {
  description = "Fargate memory in MiB for the frontend task"
  type        = number
}

variable "backend_cpu" {
  description = "Fargate CPU units for the backend task"
  type        = number
}

variable "backend_memory" {
  description = "Fargate memory in MiB for the backend task"
  type        = number
}

variable "frontend_desired_count" {
  description = "Initial task count for the active frontend colour"
  type        = number
}

variable "backend_desired_count" {
  description = "Initial task count for the active backend colour"
  type        = number
}

variable "log_retention_days" {
  description = "CloudWatch log retention for container logs"
  type        = number
}

variable "frontend_security_group_id" {
  description = "ID of the frontend security group"
  type        = string
}

variable "backend_security_group_id" {
  description = "ID of the backend security group"
  type        = string
}

# Blue/Green Target Group ARNs for Frontend
variable "frontend_blue_target_group_arn" {
  description = "ARN of the frontend blue target group"
  type        = string
}

variable "frontend_green_target_group_arn" {
  description = "ARN of the frontend green target group"
  type        = string
}

# Blue/Green Target Group ARNs for Backend
variable "backend_blue_target_group_arn" {
  description = "ARN of the backend blue target group"
  type        = string
}

variable "backend_green_target_group_arn" {
  description = "ARN of the backend green target group"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS instance endpoint"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "frontend_image" {
  description = "Container image for the frontend task. Must listen on 8080."
  type        = string
}

variable "frontend_command" {
  description = "Container command override for the frontend. Empty list uses the image's default."
  type        = list(string)
  default     = []
}

variable "backend_image" {
  description = "Container image for the backend task. Must listen on 8080."
  type        = string
}

variable "backend_command" {
  description = "Container command override for the backend. Empty list uses the image's default."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}