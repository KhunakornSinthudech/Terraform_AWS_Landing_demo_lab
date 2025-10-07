output "input_bucket_name" {
  description = "Name of the input S3 bucket."
  value       = local.input_bucket_id
}

output "output_bucket_name" {
  description = "Name of the output S3 bucket."
  value       = local.output_bucket_id
}

output "mediaconvert_queue_arn" {
  description = "ARN of the MediaConvert queue in use."
  value       = local.queue_arn
}

output "mediaconvert_role_arn" {
  description = "Service role ARN used by MediaConvert."
  value       = aws_iam_role.mc_service_role.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function that submits MediaConvert jobs."
  value       = aws_lambda_function.mc_submit.function_name
}
