resource "aws_instance" "vm" {
  ami                     = var.config.ec2_instance_ami
  instance_type           = var.config.ec2_instance_type
  key_name                = var.config.ec2_instance_key_name
  vpc_security_group_ids  = [aws_security_group.sg.id]
  subnet_id               = var.config.create_on_public_subnet ? var.config.public_subnet : var.config.private_subnet
  disable_api_termination = var.config.enable_termination_protection
  iam_instance_profile = aws_iam_instance_profile.cloudwatch_instance_profile.name
  tags                    = var.tags
  root_block_device {
    volume_size = var.config.root_volume_size
  }
}

resource "aws_eip" "instance_eip" {
  count    = var.config.create_on_public_subnet ? 1 : 0
  instance = aws_instance.vm.id
  domain   = "vpc"
}
