# modules/aws-backup/main.tf
# This file defines ONLY the AWS Backup resources for the module.
# No terraform { backend } block.
# No region parsing.
# No module orchestration.

# Example resource (replace with your actual backup resources):

resource "aws_backup_vault" "this" {
  name        = var.vault_name
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

resource "aws_backup_plan" "this" {
  name = var.plan_name
  rule {
    rule_name         = var.rule_name
    target_vault_name = aws_backup_vault.this.name
    schedule          = var.schedule
    lifecycle {
      delete_after = var.delete_after_days
    }
  }
  tags = var.tags
}

resource "aws_backup_selection" "this" {
  name         = var.selection_name
  iam_role_arn = var.iam_role_arn
  plan_id      = aws_backup_plan.this.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.selection_tag_key
    value = var.selection_tag_value
  }
}
