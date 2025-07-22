variable "region" {}
variable "environment" {}
variable "project" {}

variable "log_group_name" {}
variable "schedule" {
  description = "Schedule expression, e.g., rate(1 hour)"
}

variable "tags" {
  type = map(string)
}

variable "aws_account" {
  type        = string
  description = "AWS account name (e.g. sandbox, stage)"
}