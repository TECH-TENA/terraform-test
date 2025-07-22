# AWS KMS Auto-Rotation Enforcement Lambda - Terraform

This Terraform configuration provisions an AWS Lambda function to automatically check AWS KMS keys for auto-rotation compliance, enable rotation where it's disabled, log the actions, and optionally notify via Mattermost.

---

## Module Structure

- **KMS Auto-Rotation Lambda Module**: Sets up a Lambda function to:
  - Automatically scan AWS customer-managed KMS keys.
  - Check if each key has automatic rotation enabled.
  - If not enabled, automatically enable rotation for that key.
  - Log compliance results and any changes into a DynamoDB table with a unique `compliance_check_id`.
  - Optionally send notifications to a configured Mattermost webhook.
  - Log operational details and errors to a CloudWatch log group for auditing and debugging.

---

## Variables

### Lambda Enforcement Configuration (`config`)
All variables used within the Lambda resource need to be defined under the `config` block. These values are referenced using `var.config`.

- **lambda_function_name** (string): The name of the Lambda function (e.g., `kms-rotation-enforcer`).
- **dynamodb_table_name** (string): The name of the DynamoDB table to store compliance and enforcement logs (e.g., `kms-rotation-logs`).
- **mattermost_webhook_url** (string): The URL of the Mattermost webhook to send notifications (optional).
- **role_name** (string): The name of the IAM role associated with the Lambda function (e.g., `kms-enforcement-lambda-role`).
- **lambda_zip_file** (string): The path to the Lambda deployment zip file (e.g., `lambda.zip`).
- **lambda_run_schedule** (string): The schedule for Lambda execution (e.g., `"rate(5 minutes)"`).
- **log_retention_days** (number): Number of days to retain logs in the CloudWatch log group.
- **runtime** (string): The runtime environment for the Lambda function (e.g., `python3.10`).
- **timeout** (number): The function execution timeout in seconds.

### Tags Configuration (`tags`)
- **tags** (map of strings): A map of tags to apply to the Lambda resources (e.g., `{ "environment": "development", "team": "Webforx" }`).

---

## Usage

To use this configuration, define your Lambda enforcement setup under the `config` block:

```hcl
module "kms_auto_rotation_lambda" {
  source = "../../../modules/kms-auto-rotation-lambda"
  config = local.lambda_config
  tags   = local.env.tags
}
```
```hcl
run terraform init
    terraform plan
    terrform apply
```
Either of terraform plan or apply should genrate the zip file for the function on first run and will re-zip it if changes are made to the lambda_function file or or folder.