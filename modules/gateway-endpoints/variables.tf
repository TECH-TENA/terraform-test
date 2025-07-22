variable "config" {
  description = "VPC configuration block"
  type = object({
    vpc_id         = string
    route_table_id = string
  })
}

variable "region" {
  description = "The AWS region where all resources will be provisioned."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  type = map(string)
}
