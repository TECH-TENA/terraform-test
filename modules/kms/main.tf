resource "aws_kms_key" "autoscaling_ssm" {
  description             = "KMS key for Auto Scaling and SSM"
  enable_key_rotation     = true
  deletion_window_in_days = var.config.deletion_window
  policy                  = data.aws_iam_policy_document.kms_policy_autoscaling_ssm.json
  tags                    = var.tags
}

resource "aws_kms_alias" "autoscaling_ssm" {
  name          = "alias/${var.config.alias}/autoscaling_ssm"
  target_key_id = aws_kms_key.autoscaling_ssm.key_id
}


resource "aws_kms_key" "ec2_s3" {
  description             = "KMS key for EC2 (EBS) and S3"
  enable_key_rotation     = true
  deletion_window_in_days = var.config.deletion_window
  policy                  = data.aws_iam_policy_document.kms_policy_ec2_s3.json
  tags                    = var.tags
}

resource "aws_kms_alias" "ec2_s3" {
  name          = "alias/${var.config.alias}/ec2_s3"
  target_key_id = aws_kms_key.ec2_s3.key_id
}
