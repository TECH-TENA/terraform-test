variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs"
}

variable "delete_default_vpc" {
description = "Set to true to delete the default VPC in this region before provisioning."
type = bool
default = false
}

variable "config" {
  description = "Configuration for VPC, availability zones, and NACL rules"
  type = object({
    vpc_cidr             = string
    enable_dns_support   = bool
    enable_dns_hostnames = bool
    availability_zones   = list(any)
    control_plane_name   = string

    open_inbound_acl_rules = list(object({
      rule_number     = number
      rule_action     = string
      protocol        = string
      from_port       = optional(number)
      to_port         = optional(number)
      icmp_code       = optional(number)
      icmp_type       = optional(number)
      cidr_block      = optional(string)
      ipv6_cidr_block = optional(string)
    }))

    open_outbound_acl_rules = list(object({
      rule_number     = number
      rule_action     = string
      protocol        = string
      from_port       = optional(number)
      to_port         = optional(number)
      icmp_code       = optional(number)
      icmp_type       = optional(number)
      cidr_block      = optional(string)
      ipv6_cidr_block = optional(string)
    }))
  })

}
