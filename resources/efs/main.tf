terraform {
  backend "s3" {
    bucket         = "development-webforx-sandbox-tf-state"
    key            = "connect/efs/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }
}

locals {
  # Load YAML files
  env = merge(
    yamldecode(file("${path.module}/../../environments/region.yaml")).alias,
    yamldecode(file("${path.module}/../../environments/connect.yaml"))
  )



  # Build the complete EFS configuration enriched with VPC and Subnets.

  # Build the complete EFS configuration enriched with VPC, Subnets, and tags.


  # Build the complete EFS configuration enriched with VPC and Subnets.
(Update resources/efs/main.tf)

  # Build the complete EFS configuration enriched with VPC and Subnets.

  efs_env = merge(
    local.env.efs_shared,
    {
      vpc_id  = local.env.vpc.vpc_id,
      subnets = local.env.vpc.private_subnets
    }
  )
}

# Call the EFS module with the complete configuration
module "efs" {
  source     = "../../modules/efs"
  efs_config = local.efs_env
}

output "debug_ec2_sg_ids" {
  value = module.efs.debug_ec2_sg_ids
}
