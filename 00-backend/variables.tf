variable "project" {
  description = "Project prefix"
  type        = string
  default     = "oak-lab"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "tf_state_bucket_name" {
  description = "Override bucket name (optional). If null, use <project>-tfstate-<region>"
  type        = string
  default     = null
}

variable "tf_lock_table_name" {
  description = "Override DynamoDB lock table name (optional)"
  type        = string
  default     = null
}

variable "use_kms" {
  description = "Use SSE-KMS instead of SSE-S3"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN (required if use_kms = true)"
  type        = string
  default     = null
}
