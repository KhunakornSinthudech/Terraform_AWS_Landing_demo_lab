
output "db_endpoints" {
  value = { for k, inst in aws_db_instance.pg : k => inst.endpoint }  
}
output "db_addresss" {
  value = { for k, inst in aws_db_instance.pg : k => inst.address }  
}
output "db_ports" {
  value = { for k, inst in aws_db_instance.pg : k => inst.port }  
}
output "db_sg_ids" {
  value = { for k, sg in aws_security_group.db : k => sg.id }  
}

output "db_master_secret_arn" {
  value = {
    for k, v in aws_db_instance.pg :
    k => try(v.master_user_secret[0].secret_arn, null)
  }
}

output "db_name" {
  value = { for k, inst in aws_db_instance.pg : k => inst.db_name }  
}
output "db_host" {
  value = { for k, inst in aws_db_instance.pg : k => inst.address }  
}
output "db_port" {
  value = { for k, inst in aws_db_instance.pg : k => inst.port }  
}