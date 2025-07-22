resource "aws_efs_file_system" "shared" {
  creation_token   = var.efs_config.creation_token
  performance_mode = var.efs_config.performance_mode
  throughput_mode  = var.efs_config.throughput_mode
  encrypted        = true

  tags = {
    Name = var.efs_config.name
  }
}

resource "aws_efs_mount_target" "mount_shared" {
  for_each        = toset(var.efs_config.subnets)
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}