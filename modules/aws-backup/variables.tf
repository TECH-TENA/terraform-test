variable "vault_name" {
  description = "Name of the AWS Backup Vault"
}

variable "kms_key_arn" {
  description = "KMS Key ARN for backup vault encryption"
}

variable "plan_name" {
  description = "Name of the AWS Backup Plan"
}

variable "rule_name" {
  description = "Name of the backup rule"
}

variable "schedule" {
  description = "Backup schedule in cron format"
}

variable "delete_after_days" {
  description = "Retention period in days"
  default     = 35
}

variable "iam_role_arn" {
  description = "IAM Role ARN for AWS Backup service"
}

variable "selection_name" {
  description = "Name of the backup selection"
}

variable "selection_tag_key" {
  description = "Tag key used for selecting resources to back up"
}

variable "selection_tag_value" {
  description = "Tag value used for selecting resources to back up"
}

variable "tags" {
  description = "Standard tags to apply"
  type        = map(string)
}
