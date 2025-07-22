variable "lambda_name" {
  description = "Name of the AMI Cleanup Lambda function"
  type        = string
}

variable "ami_tag_key" {
  description = "AMI tag key used to identify AMIs for cleanup"
  type        = string
  default     = "Backup"
}

variable "ami_tag_value_prefix" {
  description = "AMI tag value prefix for cleanup filtering"
  type        = string
  default     = "true"
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for cleanup notifications"
  type        = string
}

variable "mattermost_webhook_url" {
  description = "Mattermost webhook URL for notifications"
  type        = string
  default     = ""
}

variable "cleanup_schedule" {
  description = "CloudWatch schedule expression for Lambda invocation (cron or rate)"
  type        = string
  default     = "cron(0 4 * * ? *)"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
}

variable "lambda_layers" {
  description = "List of Lambda Layer ARNs to attach"
  type        = list(string)
  default     = []
}
