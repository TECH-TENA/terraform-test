# AWS KMS Key Creation - Terraform

This Terraform configuration provisions AWS Key Management Service (KMS) keys for various services.

---

## Module Structure

- **KMS Modules**: Creates separate KMS keys for the following services:
  - EBS (Elastic Block Store)
  - S3 (Simple Storage Service)
  - SSM (AWS Systems Manager) Session Manager
  - Auto Scaling

---

## Variables

### KMS Key Configuration (`config`)
All variables used within the resources need to be defined under the `config` block, as all the values are referenced using `var.config`.

- **alias** (string): The alias of the KMS key (e.g., `ebs-key`, `s3-key`, etc.)
- **description** (string): A description for the KMS key (e.g., `KMS key for EBS`).
- **deletion_window** (number): The number of days the key will be held after being disabled.

### Tags Configuration (`tags`)
- **tags** (map of strings): A map of tags to apply to the resources for identification purposes (e.g., `{ "environment": "development", "team": "Webforx" }`).

The `tags` variable is also referenced within the resources and should be defined in your configuration accordingly.

---

## Usage

To use this configuration, you must define your KMS key setup. All variables must be passed under the `config` block.

```hcl
module "kms_ebs" {
  source = "../../../modules/kms"
  config = local.kms_ebs_config
  tags   = local.env.tags
}

module "kms_s3" {
  source = "../../../modules/kms"
  config = local.kms_s3_config
  tags   = local.env.tags
}

module "kms_ssm" {
  source = "../../../modules/kms"
  config = local.kms_ssm_config
  tags   = local.env.tags
}

module "kms_autoscaling" {
  source = "../../../modules/kms"
  config = local.kms_autoscaling_config
  tags   = local.env.tags
}
