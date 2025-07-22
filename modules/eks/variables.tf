variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs"
}

variable "config" {
  description = "Consolidated configuration for EKS cluster and node groups"
  type = object({
    eks_version              = string
    vpc_id                   = string
    public_subnet_ids        = list(string)
    private_subnet_ids       = list(string)
    endpoint_private_access  = bool
    endpoint_public_access   = bool
    capacity_type            = string
    ami_type                 = string
    instance_types           = list(string)
    disk_size                = number
    ec2_ssh_key              = string
    green                    = bool
    blue                     = bool
    green_node_color         = string
    blue_node_color          = string
    shared_owned             = string
    enable_cluster_autoscaler = bool
    control_plane_name       = string
    node_min                 = number
    desired_node             = number
    node_max                 = number
  })
}