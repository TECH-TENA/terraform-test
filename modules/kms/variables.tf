variable "config" {
  description = "Configuration for the KMS key"
  type = object({
    alias           = string
    description     = string
    deletion_window = number
  })
}

variable "tags" {
  description = "Tags for the KMS key"
  type        = map(string)
  default     = {}
}
