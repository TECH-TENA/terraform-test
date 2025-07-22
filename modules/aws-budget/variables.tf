variable "config" {
  type = object({
    budget_limit      = number
    thresholds        = list(number)
    email_subscribers = list(string)
  })
  description = "Configuration for AWS region, budget amount, and email alerts"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to resources"
}