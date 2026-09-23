variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the load balancer (the LoadBalancer metric dimension)"
  type        = string
}

variable "target_group_arn_suffixes" {
  description = "Target group ARN suffixes keyed by a short name, one unhealthy-target alarm each"
  type        = map(string)
}

variable "rds_identifier" {
  description = "Identifier of the RDS instance"
  type        = string
}

variable "db_secret_redeploy_arn" {
  description = "ARN of the Step Functions state machine that redeploys the backend after a database password rotation"
  type        = string
}

variable "alarm_email" {
  description = "Email address to notify. Creates an SNS topic and subscription when set; leave empty for alarms without notifications."
  type        = string
  default     = ""
}

variable "alarm_actions" {
  description = "Additional ARNs (SNS topics, for example an existing paging topic) to notify on alarm and recovery"
  type        = list(string)
  default     = []
}

variable "alb_5xx_threshold" {
  description = "ALB-generated 5xx responses per 5 minutes before alarming"
  type        = number
  default     = 10
}

variable "target_5xx_threshold" {
  description = "Target-generated 5xx responses per 5 minutes before alarming"
  type        = number
  default     = 25
}

variable "rds_cpu_threshold" {
  description = "Database CPU percentage before alarming"
  type        = number
  default     = 80
}

variable "rds_free_storage_threshold_bytes" {
  description = "Database free storage in bytes before alarming (default 2 GiB)"
  type        = number
  default     = 2147483648
}

variable "rds_freeable_memory_threshold_bytes" {
  description = "Database freeable memory in bytes before alarming (default 256 MiB)"
  type        = number
  default     = 268435456
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
