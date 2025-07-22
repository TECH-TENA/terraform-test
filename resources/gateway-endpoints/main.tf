locals {
  env = merge(
    yamldecode(file("${path.module}/../../environments/region.yaml")),
    yamldecode(file("${path.module}/../../environments/webforx.yaml"))
  )
}

terraform {
  required_version = ">= 1.10.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "development-webforx-sandbox-tf-state"
    key            = "webforx/gateway-endpoints/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }
}

provider "aws" {
  region = local.env.dev
}

module "gateway_endpoints" {
  source = "../../modules/gateway-endpoints"
  config = local.env.vpc
  tags   = local.env.tags
}

