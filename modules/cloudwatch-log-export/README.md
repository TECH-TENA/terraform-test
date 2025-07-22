# CloudWatch Log Export with Lambda and CloudTrail

This project automates the export of AWS CloudWatch Logs to an S3 bucket using a Lambda function triggered on a schedule. It also sets up CloudTrail for auditing AWS account activity, with logs sent to CloudWatch and S3 for compliance and archiving.

---

## Prerequisites

* AWS CLI configured with appropriate IAM credentials
* Terraform installed (>= 1.10)
* Python 3.10+ installed (used for Lambda function)
* zip utility (for packaging the Lambda function)
* IAM permissions to create:

  * Lambda functions
  * IAM roles and policies
  * CloudWatch log groups
  * CloudTrail trails
  * S3 buckets and bucket policies

---

## AWS Setup

Ensure you have an AWS account and an IAM user or role with the following permissions:

* `logs:CreateExportTask`, `logs:DescribeLogGroups`, `logs:GetLogEvents`
* `lambda:*`
* `s3:PutObject`, `s3:GetBucketPolicy`, `s3:PutBucketPolicy`
* `cloudtrail:*`
* `events:PutRule`, `events:PutTargets`

---

## Setup Instructions

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-username/cloudwatch-log-export.git
   cd cloudwatch-log-export
   ```

2. **Install Python packages (optional for local testing):**

   ```bash
   pip install boto3
   ```

3. **Zip the Lambda function:**

   ```bash
   zip ../lambda_function_payload.zip export_logs.py
   ```

4. **Prepare Terraform:** Navigate to the Terraform module directory:

## 'aws configure' with AWS sandbox required before running terraform: at the terminal level. AWS Sandbox credentials values (Access ID, Secret key, Token) must be stored or ingested in vault in Dev/secrets folder before running CI/CD

   ```bash
   cd resources/cloudwatch-log-export
   terraform init
   ```

---

## Define Input Variables

Set the following values in a `terraform.tfvars` or using `-var` flags:

```hcl
region         = "us-east-1"
environment    = "dev"
project        = "webforx"
aws_account    = "sandbox"
log_group_name = "/aws/lambda/your-log-group"
schedule       = "rate(1 hour)"  # or "cron(0 * * * ? *)"  # every hour
bucket_name    = "your-log-export-bucket"
tags = {
  environemnt = "dev"
  project = "webforx"
  aws_account    = "sandbox"

}
```

---

## Deploy Infrastructure

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan  # Manually review and approve the execution plan
terraform apply tfplan # Deploy the resources
```

# Manual Approval for GitHub Actions Environment

To set **manual approval** for an environment in GitHub Actions, follow these steps:

---

## Steps to Set Manual Approval for an Environment in GitHub Actions

## 1. **Go to Your Repository Settings**

- Navigate to your GitHub repo (e.g., `https://github.com/<your-org>/<your-repo>`).
- Click on **"Settings"** (top menu bar).

## 2. **Open Environments**

- In the left sidebar, scroll down and click **"Environments"**.

## 3. **Create or Select an Environment**

- Click the **“New environment”** button (if it doesn't exist yet).
  - Example: `sandbox-approval` (must match `environment: sandbox-approval` in your workflow).
- Or click the existing environment name to edit it.

## 4. **Add Required Reviewers**

- Under the **"Environment protection rules"**, find **“Required reviewers”**.
- Click **"Add required reviewers"**.
- Select one or more GitHub users or teams who must **approve before the workflow can continue**.
- Click **"Save protection rules"**.

---

## Example Protection Setting Summary

| Setting                | Value                                  |
|------------------------|----------------------------------------|
| Environment name       | `sandbox-approval` (must match YAML)   |
| Required reviewers     | `you@example.com`, `team/devops`       |
| Wait timer (optional)  | Leave unset unless you want delays     |

---

## GitHub Actions Behavior

Once configured:

- When your workflow reaches the job with `environment: sandbox-approval`, GitHub **pauses** the job.
- A reviewer must **approve via the GitHub UI**.
- After approval, the job (e.g., `terraform-apply`) will continue.

---

## What It Looks Like

- Under the **Actions** tab in the workflow run:
  - You’ll see a **“Review required”** status.
  - A button appears: **“Review deployments”** → then **“Approve and deploy”**.


---

## Testing

After deployment:

* Check CloudWatch > Rules for the scheduled Lambda
* Check S3 bucket for exported log files
* Verify CloudTrail is active and sending logs to CloudWatch

---

## Project Structure

```
cloudwatch-log-export/
│
├── README.md
├── modules/
│   ├── log_export/
│   │   ├── log_export.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── log_export_scheduler/
│       ├── log_scheduler.tf
│       ├── outputs.tf
│       ├── variables.tf
│       └── lambda/
│           └── export_logs.py
│
└── resources/
    ├── main.tf
    
```




