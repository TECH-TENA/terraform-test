output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_name
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = module.autoscaling.launch_template_id
}