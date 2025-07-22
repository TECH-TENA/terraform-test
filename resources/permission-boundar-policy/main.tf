locals {
  env = yamldecode(file("${path.module}/../../environments/region.yaml")) 
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
    key            = "webforx/permission-boundary-policy/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }
}



provider "aws" {
  region = local.env.dev
}

module "permissions_boundary" {
  source = "../../modules/permission-boundary-policy"
}