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

variable "availability_zones" {
  description = "Availability zones, in order. Public, private and database subnets are created one per zone by index; the first zone also hosts the NAT gateway."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required for an internet-facing ALB."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per availability zone"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two public subnet CIDRs are required for an internet-facing ALB."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per availability zone. Backend tasks are spread across all of them."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 1
    error_message = "At least one private subnet CIDR is required."
  }
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for the database subnets, one per availability zone"
  type        = list(string)

  validation {
    condition     = length(var.database_subnet_cidrs) >= 2
    error_message = "At least two database subnet CIDRs are required for an RDS subnet group."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
