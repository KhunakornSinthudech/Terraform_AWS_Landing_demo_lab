output "vpc_id" { value = aws_vpc.oaklab.id }
output "public_subnet_ids"  { value = [for _, s in aws_subnet.public  : s.id] }
output "private_subnet_ids" { value = [for _, s in aws_subnet.private : s.id] }
output "public_subnet_ids_by_key"  { value = { for k, s in aws_subnet.public  : k => s.id } }
output "private_subnet_ids_by_key" { value = { for k, s in aws_subnet.private : k => s.id } }