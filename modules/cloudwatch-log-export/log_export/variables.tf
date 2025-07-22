variable "region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod)"
}

variable "project" {
  type        = string
  description = "Project name (e.g. webforx)"
}

variable "aws_account" {
  type        = string
  description = "AWS account name (e.g. sandbox, stage)"
}

variable "log_retention_days" {
  type        = number
  description = "Retention period in CloudWatch logs"
}

variable "transition_days" {
  type        = number
  description = "Days before transitioning logs to Glacier"
}

variable "expiration_days" {
  type        = number
  description = "Days before deleting logs from S3"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for all resources"
}
