variable "config" {
  description = "RDS and infrastructure configuration"
  type = object({
    aws_region_main              = string
    name                         = string
    engine                       = string
    engine_version               = string
    parameter_group_family       = string
    instance_class               = string
    allocated_storage            = number
    max_allocated_storage        = number
    port                         = number
    multi_az                     = bool
    publicly_accessible          = bool
    vpc_id                       = string
    private_subnet_ids           = list(string)
    app_security_group_id        = string
    subnet_group_name            = string
    monitoring_interval          = number
    monitoring_role_name         = string
    performance_retention        = number
    skip_final_snapshot          = bool
    backup_retention_days        = number
    sns_topic_name               = string
    mattermost_webhook_url       = string
    performance_insights_enabled = bool
    ssm_username_param           = string
    ssm_password_param           = string
    ssm_dbname_param             = string
    notification_emails          = list(string)
  })
  validation {
    condition     = contains(["postgres", "mysql", "mariadb", "sqlserver-se", "sqlserver-ee"], var.config.engine)
    error_message = "Invalid engine type. Allowed values: postgres, mysql, mariadb, sqlserver-se, sqlserver-ee"
  }
}

variable "kms_config" {
  description = "Configuration object for the KMS key used to encrypt the RDS instance."
  type = object({
    description             = string
    deletion_window_in_days = number
    enable_key_rotation     = bool
    rotation_alias_name     = string
  })
}

variable "monitoring_config" {
  description = "Settings for CloudWatch monitoring and alarms."
  type = object({
    namespace                   = string
    cpu_metric_name             = string
    cpu_period                  = number
    cpu_statistic               = string
    cpu_threshold               = number
    cpu_evaluation_periods      = number
    cpu_comparison_operator     = string
    cpu_alarm_description       = string
    storage_metric_name         = string
    storage_period              = number
    storage_statistic           = string
    storage_threshold           = number
    storage_evaluation_periods  = number
    storage_comparison_operator = string
    storage_alarm_description   = string
  })
}

variable "db_username_ssm_path" {
  description = "Path to the SSM parameter for the database username."
  type        = string
}

variable "db_password_ssm_path" {
  description = "Path to the SSM parameter for the database password."
  type        = string
}

variable "db_name_ssm_path" {
  description = "Path to the SSM parameter for the database name."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}

variable "sns_topic_name" {
  description = "The name of the SNS topic for RDS notifications"
  type        = string
}

variable "notification_emails" {
  description = "A list of email addresses to receive RDS notifications"
  type        = list(string)
  validation {
    condition     = length(var.notification_emails) > 0
    error_message = "notification_emails must not be empty. Add valid emails to webforx.yaml."
  }
}
