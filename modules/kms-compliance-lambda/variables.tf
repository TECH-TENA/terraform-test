variable "config" {
  description = "Configuration for the KMS key rotation Lambda setup"
  type = object({
    lambda_function_name   = string
    dynamodb_table_name    = string
    mattermost_webhook_url = string
    role_name              = string
    lambda_run_schedule    = string
    log_retention_days     = number
    runtime                = string
    timeout                = number
  })
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}
