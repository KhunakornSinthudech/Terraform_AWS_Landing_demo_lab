output "vpc_id" { value = module.network.vpc_id }
output "public_subnets" { value = module.network.public_subnet_ids }
output "private_subnets" { value = module.network.private_subnet_ids }
output "region" { value = var.region }


output "webapp_urls" {
  description = "Webapp URLs module"
  value       = module.compute.webapp_urls
}

output "input_bucket_name" {
  description = "Name of the input S3 bucket."
  value       = module.media_converter.input_bucket_name
}

output "output_bucket_name" {
  description = "Name of the output S3 bucket."
  value       = module.media_converter.output_bucket_name
}

output "lambda_function_name" {
  description = "Name of the Lambda function that submits MediaConvert jobs."
  value       = module.media_converter.lambda_function_name
}