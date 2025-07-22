variable "efs_config" {
  description = "Configuration object for the EFS module"

  type = object({
    name             = string
    creation_token   = string
    performance_mode = string
    throughput_mode  = string
    vpc_id           = string
    subnets          = list(string)
  })
}

