output "log_group_name" {
  value       = var.enabled ? var.log_group_name : null
  description = "CloudWatch Log Group used for system logs."
}

output "ssm_parameter_name" {
  value       = var.enabled ? aws_ssm_parameter.cw_config[0].name : null
  description = "SSM parameter name containing the CloudWatch agent config."
}

# output "install_association_id" {
#   value       = var.enabled ? aws_ssm_association.install_cwagent[0].id : null
#   description = "SSM association id for agent installation."
# }

# output "configure_association_id" {
#   value       = var.enabled ? aws_ssm_association.configure_cwagent[0].id : null
#   description = "SSM association id for agent configuration."
# }