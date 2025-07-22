
# Inline IAM policy for Cost Explorer access
resource "aws_iam_policy" "lambda_custom_access_policy" {
  name = format("%s-%s-lambda-custom_access-policy", var.tags["environment"], var.tags["project"])
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ce:GetCostAndUsage"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ],
        Resource = "*"
      },
       {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}