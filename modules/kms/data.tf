data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms_policy_autoscaling_ssm" {
  statement {
    sid     = "EnableIAMUserPermissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = ["*"]
  }

  statement {
    sid    = "AllowServiceUsageAutoScalingSSM"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "Service"
      identifiers = [
        "autoscaling.amazonaws.com", # for Auto Scaling
        "ssm.amazonaws.com"          # for SSM Session Manager
      ]
    }
    resources = ["*"]
  }
}
##############################################################################################

data "aws_iam_policy_document" "kms_policy_ec2_s3" {
  statement {
    sid     = "EnableIAMUserPermissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = ["*"]
  }

  statement {
    sid    = "AllowServiceUsageEC2S3"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com", # for EBS
        "s3.amazonaws.com"   # for S3
      ]
    }
    resources = ["*"]
  }
}
