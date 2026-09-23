output "sns_topic_arn" {
  description = "ARN of the alarm notification topic, or null when alarm_email is not set"
  value       = one(aws_sns_topic.alarms[*].arn)
}

output "alarm_names" {
  description = "Names of every alarm created"
  value = concat(
    [for a in aws_cloudwatch_metric_alarm.unhealthy_targets : a.alarm_name],
    [
      aws_cloudwatch_metric_alarm.alb_5xx.alarm_name,
      aws_cloudwatch_metric_alarm.target_5xx.alarm_name,
      aws_cloudwatch_metric_alarm.rds_cpu.alarm_name,
      aws_cloudwatch_metric_alarm.rds_free_storage.alarm_name,
      aws_cloudwatch_metric_alarm.rds_freeable_memory.alarm_name,
      aws_cloudwatch_metric_alarm.db_secret_redeploy_failed.alarm_name,
    ]
  )
}
