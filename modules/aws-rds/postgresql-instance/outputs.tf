output "rds_endpoint" {
  description = "The RDS endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_arn" {
  description = "The ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = module.rds.db_instance_identifier
}

output "kms_key_id" {
  description = "The ARN of the KMS key used for encryption"
  value       = aws_kms_key.rds_kms.arn
  sensitive   = true
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.rds_data_bucket.id
  description = "Name of the RDS-related S3 bucket"
}

output "s3_bucket_region" {
  value       = var.config.aws_region_main
  description = "Region for the RDS-related S3 bucket"
}
