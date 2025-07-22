locals {
  env_config = yamldecode(file("${path.module}/../../environments/webforx.yaml"))
}

module "rds_postgres_instance" {
  source = "../../modules/aws-rds/postgresql-instance"
  config = local.env_config.rds.config
  db_username_ssm_path = local.env_config.rds.config.ssm_username_param
  db_password_ssm_path = local.env_config.rds.config.ssm_password_param
  db_name_ssm_path     = local.env_config.rds.config.ssm_dbname_param
  kms_config           = local.env_config.rds.kms_config
  sns_topic_name       = local.env_config.rds.config.sns_topic_name
  notification_emails  = local.env_config.rds.config.notification_emails
  monitoring_config    = local.env_config.rds.monitoring_config
  tags                 = local.env_config.tags
}

output "rds_endpoint"    { value = module.rds_postgres_instance.rds_endpoint }
output "rds_arn"         { value = module.rds_postgres_instance.rds_arn }
output "rds_instance_id" { value = module.rds_postgres_instance.rds_instance_id }
output "kms_key_id"      { value = module.rds_postgres_instance.kms_key_id }
output "s3_bucket_name"  { value = module.rds_postgres_instance.s3_bucket_name }
output "s3_bucket_region" { value = module.rds_postgres_instance.s3_bucket_region }
