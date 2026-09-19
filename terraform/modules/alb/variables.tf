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
  description = "IDs of the public subnets for the ALB (at least two, in different availability zones)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "An internet-facing ALB requires at least two subnets in different availability zones."
  }
}

variable "certificate_arn" {
  description = "ARN of an ACM certificate for the HTTPS listener. Leave empty to serve HTTP only."
  type        = string
  default     = ""
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "short_name" {
  description = "Short project name used where AWS limits names to 32 characters (ALB, target groups)"
  type        = string
}

variable "frontend_health_check_path" {
  description = "HTTP path the ALB probes on frontend tasks"
  type        = string
}

variable "backend_health_check_path" {
  description = "HTTP path the ALB probes on backend tasks"
  type        = string
}

variable "test_listener_port" {
  description = "Port of the HTTP test listener that fronts the inactive colour"
  type        = number
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}