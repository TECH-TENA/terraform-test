# provider "aws" {
#   region = var.region
# }

data "aws_caller_identity" "current" {}

locals {
  log_bucket_name       = format("%s-%s-%s-sandbox-log-export", var.environment, var.project, var.aws_account)
  lambda_name           = format("%s-%s-%s-sandbox-log-export-lambda", var.environment, var.project, var.aws_account)
  lambda_log_group_name = format("/aws/lambda/%s-%s-%s-sandbox-lambda-logs", var.environment, var.project, var.aws_account)
  cloudtrail_log_group  = format("/aws/cloudtrail/%s-%s-%s-sandbox-system-logs", var.environment, var.project, var.aws_account)
  lambda_role_name      = format("%s-%s-%s-sandbox-lambda-exec-role", var.environment, var.project, var.aws_account)
  cloudtrail_role_name  = format("%s-%s-%s-sandbox-cloudtrail-logs-role", var.environment, var.project, var.aws_account)
  cloudtrail_policy     = format("%s-%s-%s-sandbox-cloudtrail-logs-policy", var.environment, var.project, var.aws_account)
  cloudtrail_name       = format("%s-%s-%s-sandbox-system-cloudtrail", var.environment, var.project, var.aws_account)
}

# 1. Create S3 Bucket for Logs
resource "aws_s3_bucket" "log_bucket" {
  bucket        = local.log_bucket_name
  force_destroy = true
  tags          = var.tags
}

# 2. Bucket Policy
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailACLCheck",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.log_bucket.arn
      }
    ]
  })
}


# 3. S3 Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "LogLifecycleRule"
    status = "Enabled"

    filter {}

    transition {
      days          = var.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

# 4. CloudWatch Log Group for Lambda Logs
resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.lambda_log_group_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# 5. IAM Role for Lambda → CloudWatch
resource "aws_iam_role" "lambda_exec_role" {
  name = local.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 6. CloudWatch Log Group for CloudTrail System Logs
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = local.cloudtrail_log_group
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# 7. IAM Role and Policy for CloudTrail → CloudWatch
resource "aws_iam_role" "cloudtrail_logs_role" {
  name = local.cloudtrail_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "cloudtrail.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs_policy" {
  name = local.cloudtrail_policy
  role = aws_iam_role.cloudtrail_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

# 8. CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.log_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_logs_role.arn
  depends_on                    = [aws_s3_bucket_policy.log_bucket_policy]
}
