resource "aws_dynamodb_table" "rotation_logs" {
  name         = var.config.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "compliance_check_id"

  attribute {
    name = "compliance_check_id"
    type = "S"
  }

  tags = var.tags
}
