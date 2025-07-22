# Terraform AWS Budget and S3 Backend Configuration

This repository contains Terraform modules and configurations to manage AWS resources for the Webforx Technology environment, including budget settings, SNS alerts, and S3 backend configuration.

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
│   └── webforx.yaml                    # Webforx environment configuration (budget, tags, etc.)
├── modules                             # Reusable Terraform modules
│   ├── aws-budget                      # Module to configure AWS Budgets and SNS alerts
│       ├── main.tf                     # Main configuration for AWS Budget
│       ├── outputs.tf                  # Outputs from the AWS Budget module
│       └── variables.tf                # Input variables for the AWS Budget module
├── resources                           # Custom Terraform resources
│   ├── aws-budget                      # AWS Budget resource configuration
│       ├── main.tf                     # Main configuration for AWS Budget
│       ├── README

```

## Configuration Files

### `webforx.yaml`

This file contains environment-specific configurations, including metadata tags, S3 settings, and AWS budget settings.

```yaml
tags:
  owner: "Webforx Technology"
  team: "Webforx Team"
  environment: "development"
  project: "webforx"
  created_by: "Terraform"
  cloud_provider: "aws"


aws-budget:
  aws_region_main: "us-east-1"
  budget_limit: 200
  thresholds: [80, 100]
  email_subscribers:
    - s4clovis.wft@gmail.com
    - s8dubois.wft@gmail.com
    - s8jenny.wft@gmail.com
    - s9alseny.wft@gmail.com
    - s9charles.wft@gmail.com
    - s9sophia.wft@gmail.com
```

### `region.yaml`

This file defines the AWS region for the development environment and aliases for backup regions.

```yaml
dev: us-east-1
alias:
  aws_region_main: us-east-1
  aws_region_backup: us-west-2
```

## Terraform Configuration

### Backend Configuration

The Terraform state is stored remotely in an S3 bucket with DynamoDB for state locking:

```hcl
backend "s3" {
  bucket         = "development-webforx-sandbox-tf-state"
  key            = "webforx/aws-budget/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "development-webforx-sandbox-tf-state-lock"
}
```

### AWS Budget Module

The `aws-budget` module creates an AWS budget, SNS topic, and email subscriptions for budget alerts. The module is configured using the `webforx.yaml` configuration file.

### Example Terraform Configuration:

```hcl
locals {
  env = merge(
    yamldecode(file("${path.module}/../../environments/region.yaml")).alias,
    yamldecode(file("${path.module}/../../environments/webforx.yaml")).aws-budget,
  )
}

resource "aws_sns_topic" "budget_alerts" {
  name = format("%s-%s-aws-budget-alerts", local.env.tags["environment"], local.env.tags["project"])
}

resource "aws_budgets_budget" "monthly_budget" {
  name          = format("%s-%s-monthly-budget", local.env.tags["environment"], local.env.tags["project"])
  budget_type   = "COST"
  limit_amount  = local.env.budget_limit
  limit_unit    = "USD"
  time_unit     = "MONTHLY"

  dynamic "notification" {
    for_each = local.env.thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = local.env.email_subscribers
    }
  }
}
```

## Initialization and Usage

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
