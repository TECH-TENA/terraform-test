terraform {
  backend "s3" {
    bucket         = "development-webforx-sandbox-tf-state"
    key            = "webforx/rds/main/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
