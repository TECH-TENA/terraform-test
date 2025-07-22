output "key_id_autoscaling_ssm" {
  value = aws_kms_key.autoscaling_ssm.id
}

output "key_id_ec2_s3" {
  value = aws_kms_key.ec2_s3.id
}
