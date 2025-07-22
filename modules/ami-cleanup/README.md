# AMI Cleanup & AWS Backup Automation Module

## Overview

This module delivers automated management of Amazon Machine Images (AMIs) and EC2 instance backups using AWS Lambda, AWS Backup, and supporting AWS resources.  
**All configuration, notification endpoints, and tagging are centralized in `webforx.yaml`.**

---

## Key Features

- Enforces retention of only the latest AMI per EC2 instance (minimizes storage cost and risk).
- Automatically deletes older/duplicate AMIs and all associated snapshots.
- **Multi-channel notification:** Sends alerts via SNS email **and** Mattermost webhook for every Lambda run (success, failure, info).
- Logs every cleanup run to AWS Systems Manager (SSM) Parameter Store for auditability.
- Schedules via CloudWatch Events (EventBridge) for fully automated operation.
- All resource tagging and key configuration are **parameterized and standardized**.
- **IAM roles and permissions managed via Terraform** for least-privilege security.
- All module inputs, outputs, and notification endpoints are controlled in `webforx.yaml` (not in code).

---

## Directory Structure

modules/
└── ami-cleanup/
├── main.tf
├── variables.tf
├── scripts/
│ └── lambda_function.py
└── README.md
resources/
└── aws-backup/
└── main.tf
environments/
└── webforx.yaml


## How It Works

1. **AWS Backup**
   - Backups are managed via `aws_backup_*` resources.
   - Only EC2 instances with a specific tag (e.g., `Backup=true`) are included.

2. **AMI Cleanup Lambda**
   - Scheduled by CloudWatch Events based on your `webforx.yaml` configuration.
   - On every run:
      - Finds all AMIs with the configured tag(s), groups by instance.
      - Keeps the most recent AMI per instance; deletes all older ones and their snapshots.
      - Notifies operations team by email and Mattermost (details in notification).
      - Logs event metadata and results to SSM Parameter Store.

3. **Centralized Notification Management**
   - All recipients and endpoints are defined in `webforx.yaml` (`notification_emails`, `mattermost_webhook_url`).
   - No need to edit HCL or AWS Console to add/remove recipients—**just edit YAML**.

## Deployment Instructions

### **Prerequisites**
- AWS CLI credentials with sufficient permissions for EC2, Lambda, IAM, SNS, SSM, and CloudWatch.
- Terraform >= 1.3.0
- `archive` provider enabled for Lambda packaging.

### **Step 1: Prepare Your Environment**
- Clone the repository and navigate to your Terraform root.
- Ensure `webforx.yaml` is present and updated with all required configuration values.

### **Step 2: Tagging Resources for Backup**
- Tag any EC2 instance to be backed up and managed, e.g.:  
Key=Backup, Value=true


### **Step 3: Update Configuration as Needed**

`environments/webforx.yaml`:
```yaml
ami_cleanup:
lambda_name: "ami-cleanup-lambda"
ami_tag_key: "Backup"
ami_tag_value_prefix: "true"
sns_topic_arn: "arn:aws:sns:us-east-1:xxxxxxxxxxxx:ami-cleanup-notifications"
cleanup_schedule: "cron(0 4 * * ? *)"
notification_emails:
  - s9charles.wft@gmail.com
  - s9sophia.wft@gmail.com
  # add more as needed
mattermost_webhook_url: "https://mattermost.example.com/hooks/xxxxxxxxxx"
Step 4: Deploy Resources
From /resources/aws-backup/:

terraform init
terraform plan
terraform apply

Terraform will:
  . Deploy IAM roles and policies for Lambda and Backup.
  . Build and upload the Lambda function with dependencies.
  . Create SNS topic and manage subscriptions (from YAML).
  . Set up CloudWatch scheduling and permissions.

Step 5: Validate the Setup
Lambda: In AWS Console > Lambda, find your function (ami-cleanup-*). Trigger manually to verify operation and notification flow.

CloudWatch Logs: Review for confirmation of deletion, errors, or successful operation.
Notifications: Confirm all notification emails and Mattermost messages for every run.
SSM Parameter Store: Confirm /ami-cleanup/last-run is updated with each execution.

# Adding/Changing Notification Recipients
To add/remove email or Mattermost recipients:
Edit the notification_emails list or mattermost_webhook_url in webforx.yaml.
No need to update code or manually edit SNS topics.

# Troubleshooting
No AMIs deleted:
Ensure AMIs exist, are tagged correctly, and there is more than one per instance.
No notifications:
Check the SNS topic ARN, email/Mattermost endpoints, and confirm all subscriptions.
Authorization errors:
Review IAM role policies as set in your Terraform code.
Lambda errors:
Check CloudWatch logs for runtime or packaging errors.

Module Inputs (Selected)
| Variable                 | Description                                  | Example / Default                |
| ------------------------ | -------------------------------------------- | ----------------------- |
| `lambda_name`            | Lambda function name                         | `ami-cleanup-lambda`             |    `ami_tag_key`              | Tag key to identify AMIs for cleanup           | `Backup`                       |
| `ami_tag_value_prefix`   | Tag value prefix for identifying AMIs        | `true`                           |
| `sns_topic_arn`          | SNS topic ARN for notifications              | `arn:aws:sns:us-east-1:...`      |
| `mattermost_webhook_url` | Mattermost webhook URL for notifications     | `https://...`                    |
| `cleanup_schedule`       | CloudWatch cron schedule for Lambda runs     | `cron(0 4 * * ? *)`              |
| `tags`                   | Map of tags applied to all created resources | `{ Environment = "Production" }` |


# Security & Audit
  . All AWS actions are tightly scoped in IAM policies.
  . Lambda runs are auditable via CloudWatch and SSM Parameter Store.
  . All notification and resource access is logged and traceable.

Handoff: New Engineer Checklist
  . Review main.tf for orchestration logic.
  . Update config (webforx.yaml) for environment or notification changes.
  . Test Lambda function manually before full automation.
  . Validate notifications (email, Mattermost) and logs as above.
  . Confirm all required tags and naming standards per company policy.

For future improvements:

  . To restrict SSM permission to a single parameter, update the policy as noted in code comments.
  . To add further alerting (e.g., Slack), subscribe new endpoints in webforx.yaml.

# Support
If you encounter issues not covered above, check:

  . Terraform logs, AWS CloudWatch logs, and IAM permissions.
  . SNS and SSM configuration in AWS Console.
  . For escalations, contact the Webforx DevOps engineering team.

