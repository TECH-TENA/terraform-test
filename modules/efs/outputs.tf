output "efs_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.shared.id
}

output "efs_sg_id" {
  description = "ID of the EFS security group"
  value       = aws_security_group.efs_sg.id
}

output "debug_ec2_sg_ids" {
  value = local.ec2_sg_ids
}