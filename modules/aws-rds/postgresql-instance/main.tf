terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.config.aws_region_main
}

data "aws_ssm_parameter" "db_username" {
  name = var.db_username_ssm_path
}

data "aws_ssm_parameter" "db_password" {
  name            = var.db_password_ssm_path
  with_decryption = true
}

data "aws_ssm_parameter" "db_name" {
  name = var.db_name_ssm_path
}

resource "aws_kms_key" "rds_kms" {
  description             = var.kms_config.description
  deletion_window_in_days = var.kms_config.deletion_window_in_days
  enable_key_rotation     = var.kms_config.enable_key_rotation
  tags                    = var.tags
}

resource "aws_kms_alias" "rds_alias" {
  name          = var.kms_config.rotation_alias_name
  target_key_id = aws_kms_key.rds_kms.key_id
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.config.name}-rds-sg-"
  vpc_id      = var.config.vpc_id

  ingress {
    from_port       = var.config.port
    to_port         = var.config.port
    protocol        = "tcp"
    security_groups = [var.config.app_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "main" {
  name       = var.config.subnet_group_name
  subnet_ids = var.config.private_subnet_ids
  tags       = var.tags
}

module "rds" {
  source                                = "terraform-aws-modules/rds/aws"
  version                               = "6.1.0"
  family                                = var.config.parameter_group_family
  identifier                            = var.config.name
  engine                                = var.config.engine
  engine_version                        = var.config.engine_version
  instance_class                        = var.config.instance_class
  allocated_storage                     = var.config.allocated_storage
  max_allocated_storage                 = var.config.max_allocated_storage
  db_name                               = data.aws_ssm_parameter.db_name.value
  username                              = data.aws_ssm_parameter.db_username.value
  password                              = data.aws_ssm_parameter.db_password.value
  port                                  = var.config.port
  multi_az                              = var.config.multi_az
  publicly_accessible                   = var.config.publicly_accessible
  db_subnet_group_name                  = aws_db_subnet_group.main.name
  vpc_security_group_ids                = [aws_security_group.rds.id]
  monitoring_interval                   = var.config.monitoring_interval
  monitoring_role_name                  = var.config.monitoring_role_name
  performance_insights_enabled          = var.config.performance_insights_enabled
  create_monitoring_role                = true
  performance_insights_retention_period = var.config.performance_retention
  backup_retention_period               = var.config.backup_retention_days
  skip_final_snapshot                   = var.config.skip_final_snapshot
  storage_encrypted                     = true
  kms_key_id                            = aws_kms_key.rds_kms.arn
  manage_master_user_password           = false
  tags                                  = var.tags
}

resource "aws_sns_topic" "alerts" {
  name = var.sns_topic_name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each  = toset(var.notification_emails)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_sns_topic_subscription" "mattermost_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = var.config.mattermost_webhook_url
}

resource "aws_s3_bucket" "rds_data_bucket" {
  bucket        = "${var.config.name}-bucket"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "rds_data_bucket_versioning" {
  bucket = aws_s3_bucket.rds_data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rds_data_bucket_encryption" {
  bucket = aws_s3_bucket.rds_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.rds_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "rds_data_bucket_public_access" {
  bucket = aws_s3_bucket.rds_data_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
