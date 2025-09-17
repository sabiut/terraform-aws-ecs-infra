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

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = string
}

variable "frontend_security_group_id" {
  description = "ID of the frontend security group"
  type        = string
}

variable "backend_security_group_id" {
  description = "ID of the backend security group"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS instance endpoint"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}