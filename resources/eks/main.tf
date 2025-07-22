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
    key            = "webforx/eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }
}

provider "aws" {
  region = local.env.dev
}


module "eks" {
  source               = "../../modules/eks"
  region               = local.env.dev
  tags                 = local.env.tags
  config               = local.env.eks
}


