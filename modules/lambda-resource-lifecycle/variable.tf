variable "aws_region_main" {
  description = "AWS region to deploy resources in"
  type        = string
 }

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs representing common tags to apply to AWS resources (such as Name, Environment). Tags help in organizing and identifying resources, especially in large-scale environments."
}

variable "ec2_lifecycle_config" {
  description = "Configuration for EC2 lifecycle Lambda"
  type = object({
    lambda_timeout_ec2     = number
    lambda_timeout_logger  = number
    cost_threshold         = number
    micro_max_age_days     = number
    default_max_age_days   = number
    mattermost_webhook_url = string
  })
}


