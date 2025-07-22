terraform {
  required_version = ">= 1.10.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  env = merge(
    yamldecode(file("${path.module}/../../environments/region.yaml")).alias,
    yamldecode(file("${path.module}/../../environments/webforx.yaml"))
  )
}

provider "aws" {
  region = local.env.aws_region_main
}


terraform {
  backend "s3" {
    bucket         = "development-webforx-sandbox-tf-state"
    key            = "KMS-creation-lambda-rotation/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }
}

module "kms_ebs_s3_autoscaling_ssm" {
  source = "../../modules/kms"
  config = local.env.kms.ebs_s3_ssm_autoscaling
  tags   = local.env.tags
}



module "kms-compliance-lambda" {
  source = "../../modules/kms-compliance-lambda"
  config = local.env.lambda_kms_compliant_check
  tags   = local.env.tags
}