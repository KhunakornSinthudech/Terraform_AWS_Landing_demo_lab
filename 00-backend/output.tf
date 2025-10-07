output "tf_state_bucket" {
  value       = aws_s3_bucket.state.id
  description = "S3 bucket name for Terraform remote state"
}

output "tf_state_bucket_arn" {
  value       = aws_s3_bucket.state.arn
  description = "S3 bucket ARN"
}

output "tf_lock_table" {
  value       = aws_dynamodb_table.lock.name
  description = "DynamoDB table for state locking"
}
