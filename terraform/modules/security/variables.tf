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

variable "test_listener_port" {
  description = "ALB port of the blue/green test listener that fronts the inactive colour"
  type        = number
}

variable "test_listener_cidr_blocks" {
  description = "CIDR blocks allowed to reach the test listener, for example office or CI egress ranges. Empty means no ingress rule."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}