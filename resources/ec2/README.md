# Terraform AWS Budget and S3 Backend Configuration

This repository contains Terraform modules and configurations to manage an EC2 Instance for the Webforx Technology environment.

## Directory Structure

```plaintext
terraform-module-dev
│
├── LICENSE.md                          # License information for the project
├── README.md                           # Project overview and setup instructions
├── environments                        # YAML files for different environment configurations
│   ├── README.md                       # Environment-specific setup instructions
│   ├── connect.yaml                    # Environment-specific connection settings
│   ├── region.yaml                     # AWS region-specific configuration
│   └── webforx.yaml                    # Webforx environment configuration (tags, etc.)
├── modules                             # Reusable Terraform modules
│   ├── ec2                             # Module to configure EC2 instances
│       ├── main.tf                     # Main configuration for EC2 instance
│       ├── sg.tf                       # Security group configuration
│       ├── iam_role.tf                 # IAM role for the EC2 instance
│       ├── provider.tf                 # Provider configuration
│       └── variables.tf                # Input variables for the EC2 instance module
├── resources                           # Custom Terraform resources
│   ├── ec2                             # EC2 instance resource configuration
│       ├── main.tf                     # Main configuration for EC2 instance
│       ├── README

```


## Terraform Configuration


### Ec2 Instance Module

The EC2 Instance module creates an AWS EC2 instance, along with associated resources such as a security group, IAM role, and optional configurations like user data. The module is configured using the webforx.yaml configuration file.


## Initialization and Usage


### Usage:

```hcl
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
    key            = "connect/ec2/bastion/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }
}

provider "aws" {
  region = local.env.dev
}

module "my-ec2" {
  source = "../../modules/ec2"
  config = local.env.ec2
  tags   = local.env.tags
}


```


### Initializing Terraform

To initialize the Terraform environment, run:

```bash
terraform init
```

### Applying Configuration

To apply the configuration and create resources in AWS:

```bash
terraform apply
```

Confirm the changes when prompted.

### Cleanup

To clean up the resources created by Terraform:

```bash
terraform destroy
```
