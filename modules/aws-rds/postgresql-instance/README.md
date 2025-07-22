# Webforx RDS PostgreSQL Module

## Overview

This Terraform module creates an AWS RDS PostgreSQL database (and all its supporting infrastructure) following Webforx company standards.  
You dont write or edit any Terraform code.  

**All configuration is controlled from a single YAML file (`webforx.yaml`).**

## Key Features

- **Centralized configuration:** Edit everything in one place (`webforx.yaml`).
- **No hardcoded secrets:** DB username, password, and DB name are kept in AWS SSM Parameter Store—never in code.
- **Automatic encryption:** KMS key is created (or reused) for database storage.
- **CloudWatch monitoring:** CPU and storage alarms are created automatically. Alerts go to your team by email and Mattermost.
- **Automatic notifications:** If something important happens, your team is notified instantly.
- **Idempotent and safe:** The script detects existing AWS resources and imports them into Terraform, instead of failing or duplicating.

## How to Deploy (Quick Start)

### 1. Edit `webforx.yaml`

Fill out all required fields for your environment.  

Example:

rds:
  kms_config:
    description: "KMS key for Webforx RDS"
    deletion_window_in_days: 30
    enable_key_rotation: true
    rotation_alias_name: "alias/webforx-rds-key"

  config:
    aws_region_main: "us-east-1"
    name: "webforx-core"
    engine: "postgres"
    engine_version: "14.18"
    parameter_group_family: "postgres14"
    instance_class: "db.t3.micro"
    allocated_storage: 20
    max_allocated_storage: 100
    port: 5432
    multi_az: true
    publicly_accessible: false
    vpc_id: "vpc-..."
    private_subnet_ids: [ "subnet-...", "subnet-..." ]
    app_security_group_id: "sg-..."
    subnet_group_name: "rds-subnet-group"
    monitoring_interval: 60
    monitoring_role_name: "rds-monitor"
    performance_retention: 7
    skip_final_snapshot: true
    backup_retention_days: 7
    sns_topic_name: "webforx-rds-alerts"
    ssm_username_param: "/rds/dev/username"
    ssm_password_param: "/rds/dev/password"
    ssm_dbname_param: "/rds/dev/dbname"
    username: "webforxadmin"
    password: "MyS3cur3P@ssword2025"
    db_name: "webforxcoredb"

  monitoring_config:
    namespace: "AWS/RDS"
    cpu_metric_name: "CPUUtilization"
    cpu_period: 300
    cpu_statistic: "Average"
    cpu_threshold: 85
    cpu_evaluation_periods: 2
    cpu_comparison_operator: "GreaterThanThreshold"
    cpu_alarm_description: "Webforx RDS: High CPU usage"
    storage_metric_name: "FreeStorageSpace"
    storage_period: 600
    storage_statistic: "Minimum"
    storage_threshold: 10737418240
    storage_evaluation_periods: 1
    storage_comparison_operator: "LessThanThreshold"
    storage_alarm_description: "Webforx RDS: Low storage warning"

tags:
  environment: "sandbox"
  project: "webforx-core"
  owner: "platform"

notification_emails:
  - "ops@example.com"
  - "dev@example.com"

terraform_backend:
  s3_bucket: "development-webforx-sandbox-tf-state"
  dynamodb_table: "webforx-tf-lock-sandbox"


2. # Run the Bootstrap Script
Navigate to your RDS resources directory:
cd resources/aws-rds
Run:
./bootstrap_rds.sh

What this does:

  - Reads your YAML configuration
  - Checks if required AWS resources already exist (SSM, KMS, SNS, IAM, etc.) and imports them if they do
  - Creates any missing resources
  - Prepares and runs terraform plan
  - Notifies you in Mattermost when the plan is ready

3. # Review and Apply the Plan
After the plan is generated, review it by running:
terraform show tfplan
If all looks correct, apply:
terraform apply tfplan

4. # Cleanup (Destroy)
To safely remove all resources created by this stack:
./bootstrap_rds.sh --cleanup
This destroys all managed AWS resources, (will not remove SSM parameters as it was designed to remove whatever it creates), deletes the SNS topic, and schedules KMS key deletion

Warning: Only run cleanup if you are sure nothing else depends on these resources

# How It Works
  - You edit only the YAML file; no Terraform code changes are needed
  - The script handles imports, resource creation, and updates for you
  - CloudWatch alarms send alerts to all emails and Mattermost
  - If a resource already exists, it is imported and managed by Terraform
  - Secrets are kept in AWS SSM Parameter Store, not code or version control
  - All resources are tagged to company standards

# For New Engineers
  - Never commit .tfvars or credentials to the repo
  - Only edit webforx.yaml for configuration changes
  - For new environments (dev, prod), copy and update the YAML as needed
  - Do not delete or edit shared infra (KMS, SNS) in production without platform team approval
  - Always test in a sandbox environment first
  - The script will automatically try to fix “already exists” errors by importing resources

# Troubleshooting
  - If the script fails because of missing YAML keys or AWS errors, fix your YAML and rerun
  - Check bootstrap_rds.log for detailed logs
  - If stuck, contact Platform Engineering or see the [Webforx Infrastructure Handbook]

# Module Inputs (From YAML)
| Variable             | Description                    | Required | Source       |
| -------------------- | ------------------------------ | -------- | ------------ |
| config               | RDS, networking, credentials   | Yes      | webforx.yaml |
| kms\_config          | KMS encryption/alias/rotation  | Yes      | webforx.yaml |
| monitoring\_config   | CloudWatch alarms              | Yes      | webforx.yaml |
| tags                 | Company and environment tags   | Yes      | webforx.yaml |
| sns\_topic\_name     | SNS topic for RDS alerts       | Yes      | webforx.yaml |
| notification\_emails | List of emails for alerts      | Yes      | webforx.yaml |
| ssm\_username\_param | SSM param name for DB username | Yes      | webforx.yaml |
| ssm\_password\_param | SSM param name for DB password | Yes      | webforx.yaml |
| ssm\_dbname\_param   | SSM param name for DB name     | Yes      | webforx.yaml |

Outputs
| Output             | Description                 |
| ------------------ | --------------------------- |
| rds\_endpoint      | RDS PostgreSQL endpoint URL |
| rds\_arn           | ARN of the RDS instance     |
| rds\_instance\_id  | RDS instance identifier     |
| kms\_key\_id       | ARN of the KMS key          |
| s3\_bucket\_name   | Name of the S3 bucket       |
| s3\_bucket\_region | Region of the S3 bucket     |

# CI/CD and Integration
  - A sample GitHub Actions workflow is included at .github/workflows/terraform.yml
  - This module works with other automation (backup, cleanup, rotation) using common tags and notifications

# Need Help?
  - Contact Platform Engineering for examples, help, or advanced troubleshooting
  - Refer to the [Webforx Infrastructure Handbook] for more details

Summary:
Edit your YAML file, run the script, review/apply the Terraform plan.
No manual AWS management required—everything else is automated for you.