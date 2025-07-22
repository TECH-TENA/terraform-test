variable "config" {
  type = object({
    aws_region_main   = string
    aws_region_backup = string
    force_destroy     = bool
  })
  description = "Configuration map for s3 bucket"
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs representing common tags to apply to AWS resources (such as Name, Environment). Tags help in organizing and identifying resources, especially in large-scale environments."
}
