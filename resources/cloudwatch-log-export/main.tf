module "log_export" {
  source = "../../modules/cloudwatch-log-export/log_export"

  region      = "us-east-1"
  environment = "dev"
  project     = "webforx"
  aws_account = "sandbox"


  log_retention_days = 90
  transition_days    = 90
  expiration_days    = 395

  tags = {
    environment = "development"
    project     = "webforx"
    aws_account = "sandbox"
  }
}

module "log_export_scheduler" {
  source = "../../modules/cloudwatch-log-export/log_export_scheduler"

  region      = "us-east-1"
  environment = "dev"
  project     = "webforx"
  aws_account = "sandbox"

  log_group_name = "/aws/lambda/dev-webforx-sandbox-lambda-logs"
  schedule       = "rate(1 hour)"

  tags = {
    environment = "development"
    project     = "webforx"
    aws_account = "sandbox"
  }
}
