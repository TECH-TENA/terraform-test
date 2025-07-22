module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name = var.config.name

  create_launch_template = true
  launch_template_name   = "${var.config.name}-lt"
  image_id               = var.config.ami_id
  instance_type          = var.config.instance_type
  security_groups        = [data.aws_security_group.default.id]
  vpc_zone_identifier    = data.aws_subnets.default.ids

  desired_capacity       = var.config.desired_capacity
  min_size               = var.config.min_size
  max_size               = var.config.max_size

  health_check_type         = "EC2"
  health_check_grace_period = 300

  scaling_policies = {
    cpu-policy = {
      policy_type = "TargetTrackingScaling"

      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value     = var.config.cpu_target
        disable_scale_in = false
      }
    }
  }

  tags = var.tags
}