resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = format("%s-%s-rds-high-cpu", var.tags["environment"], var.config.name)
  comparison_operator = var.monitoring_config.cpu_comparison_operator
  evaluation_periods  = var.monitoring_config.cpu_evaluation_periods
  metric_name         = var.monitoring_config.cpu_metric_name
  namespace           = var.monitoring_config.namespace
  period              = var.monitoring_config.cpu_period
  statistic           = var.monitoring_config.cpu_statistic
  threshold           = var.monitoring_config.cpu_threshold
  alarm_description   = var.monitoring_config.cpu_alarm_description
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "missing"
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "low_storage" {
  alarm_name          = format("%s-%s-rds-low-storage", var.tags["environment"], var.config.name)
  comparison_operator = var.monitoring_config.storage_comparison_operator
  evaluation_periods  = var.monitoring_config.storage_evaluation_periods
  metric_name         = var.monitoring_config.storage_metric_name
  namespace           = var.monitoring_config.namespace
  period              = var.monitoring_config.storage_period
  statistic           = var.monitoring_config.storage_statistic
  threshold           = var.monitoring_config.storage_threshold
  alarm_description   = var.monitoring_config.storage_alarm_description
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "breaching"
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
  tags = var.tags
}
