output "instance_ids" { value = { for k, i in aws_instance.this : k => i.id } }
output "private_ips" { value = { for k, i in aws_instance.this : k => i.private_ip } }
output "public_ips" { value = { for k, i in aws_instance.this : k => i.public_ip } }
output "iam_role_name" { value = aws_iam_role.ssm_ec2.name }
output "instance_names" { value = [for i in aws_instance.this : i.tags.Name] }

output "webapp_urls" {
  description = "HTTP URLs for instances with enable_webapp=true"
  value = {
    for k, i in aws_instance.this :
    k => "http://${i.public_ip}:8080/"
    if try(var.instances[k].enable_webapp, false) && try(i.public_ip, null) != null
  }
}