resource "aws_iam_role" "lambda_execution" {
  name = var.config.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.config.role_name}-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:CreateKey",
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:DescribeKey",
          "kms:DisableKey",
          "kms:ScheduleKeyDeletion",
          "kms:TagResource",
          "kms:UpdateAlias",
          "kms:ListResourceTags",
          "kms:GetKeyRotationStatus",
          "kms:EnableKeyRotation"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem"
        ],
        Resource = aws_dynamodb_table.rotation_logs.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "${aws_cloudwatch_log_group.lambda_log_group.arn}:*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeVolumes"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups"
        ],
        Resource = "*"
      }
    ]
  })
}
