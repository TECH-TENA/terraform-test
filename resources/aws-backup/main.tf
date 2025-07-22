terraform {
  backend "s3" {
    bucket         = "development-webforx-sandbox-tf-state"
    key            = "webforx/aws-backup/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.22.0, < 6.0.0"
    }
  }
}

locals {
  config              = yamldecode(file("${path.root}/../../environments/webforx.yaml"))
  aws_backup          = local.config.aws_backup
  ami_cleanup         = local.config.ami_cleanup
  tags                = local.config.tags
  kms_config          = local.config.kms_config
  notification_emails = try(local.ami_cleanup.notification_emails, [])
  region_config       = yamldecode(file("${path.root}/../../environments/region.yaml"))
  region              = local.region_config["dev"] # Adjust as needed
}

# IAM Role module for AWS Backup Service
module "iam_backup_role" {
  source = "../../modules/iam/aws-backup-role"
  tags   = local.tags
}

# Backup Module, using IAM role from module above
module "aws_backup" {
  source              = "../../modules/aws-backup"
  iam_role_arn        = module.iam_backup_role.aws_backup_service_role_arn
  vault_name          = local.aws_backup.vault_name
  kms_key_arn         = local.kms_config.arn
  plan_name           = local.aws_backup.plan_name
  rule_name           = local.aws_backup.rule_name
  schedule            = local.aws_backup.schedule
  delete_after_days   = local.aws_backup.delete_after_days
  selection_name      = local.aws_backup.selection_name
  selection_tag_key   = local.aws_backup.selection_tag_key
  selection_tag_value = local.aws_backup.selection_tag_value
  tags                = local.tags
}


# SNS Topic for AMI Cleanup Notifications
resource "aws_sns_topic" "ami_cleanup_notifications" {
  name = "ami-cleanup-notifications"
  tags = local.tags
}

# Email subscriptions for notifications
resource "aws_sns_topic_subscription" "ami_cleanup_emails" {
  for_each = toset(local.notification_emails)
  topic_arn = aws_sns_topic.ami_cleanup_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

# AMI Cleanup Module (IAM handled inside module)
module "ami_cleanup" {
  source               = "../../modules/ami-cleanup"
  lambda_name          = local.ami_cleanup.lambda_name
  ami_tag_key          = local.ami_cleanup.ami_tag_key
  ami_tag_value_prefix = local.ami_cleanup.ami_tag_value_prefix
  cleanup_schedule     = local.ami_cleanup.cleanup_schedule
  tags                 = local.tags
  sns_topic_arn        = aws_sns_topic.ami_cleanup_notifications.arn
  mattermost_webhook_url = local.ami_cleanup.mattermost_webhook_url
  region               = local.region

  lambda_layers = [
    "arn:aws:lambda:us-east-1:298350610518:layer:requests-layer:1"
  ]
}
