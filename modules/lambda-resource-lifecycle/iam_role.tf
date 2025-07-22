# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = format("%s-%s-ec2-lifecycle-lambda-role", var.tags["environment"], var.tags["project"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach Basic Lambda Execution permissions
resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach the cost explorer policy
resource "aws_iam_role_policy_attachment" "lambda_custom_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_custom_access_policy.arn
}