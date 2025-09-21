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

# Legacy variable for backward compatibility
variable "alb_target_group_arn" {
  description = "ARN of the ALB target group (deprecated - use specific blue/green variants)"
  type        = string
  default     = ""
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

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}