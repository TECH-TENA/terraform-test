variable "config" {
  type = object({
    aws_region_main   = string
    name              = string
    ami_id            = string
    instance_type     = string
    desired_capacity  = number
    min_size          = number
    max_size          = number
    cpu_target        = number
  })
  description = "Configuration map for Auto-scaling-group"
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs representing common tags to apply to AWS resources "
}
