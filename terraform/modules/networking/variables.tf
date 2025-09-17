variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for resources"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}

variable "database_subnet_cidr" {
  description = "CIDR block for database subnet"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}