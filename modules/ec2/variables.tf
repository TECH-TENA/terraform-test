variable "config" {
  type = object({
    aws_region                    = string
    ec2_instance_ami              = string
    create_on_public_subnet       = bool
    ec2_instance_type             = string
    root_volume_size              = number
    instance_name                 = string
    ec2_instance_key_name         = string
    enable_termination_protection = bool
    sg_name                       = string
    allowed_ports                 = list(number)
    allowed_ips                   = map(string)
    vpc_id                        = string
    private_subnet                = string
    public_subnet                 = string
    iam_role_name                 = string
    iam_policy_arn                = string
    iam_instance_profile_name     = string
  })
  description = "Configuration map for EC2 instance and associated resources"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to resources"
}
