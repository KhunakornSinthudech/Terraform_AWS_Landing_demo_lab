variable "project" {
  description = "Project name used as a prefix for resource names."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = null
}

# S3 buckets
variable "create_buckets" {
  description = "If true, create input/output S3 buckets; otherwise use existing bucket names."
  type        = bool
  default     = true
}

variable "input_bucket_name" {
  description = "Name of the input bucket (used when create_buckets=false)."
  type        = string
  default     = null
}

variable "output_bucket_name" {
  description = "Name of the output bucket (used when create_buckets=false)."
  type        = string
  default     = null
}

variable "input_prefix" {
  description = "S3 prefix to watch for new uploads."
  type        = string
  default     = "input/"
}

variable "output_prefix" {
  description = "S3 prefix to write transcoded outputs."
  type        = string
  default     = "outputs/"
}

variable "bucket_force_destroy" {
  description = "If true and creating buckets, allow destroy even if not empty (lab/demo only)."
  type        = bool
  default     = false
}

# MediaConvert queue
variable "create_queue" {
  description = "If true, create a MediaConvert queue; else use existing_queue_arn."
  type        = bool
  default     = true
}

variable "queue_name" {
  description = "Name for the MediaConvert queue (when create_queue=true)."
  type        = string
  default     = null
}

variable "existing_queue_arn" {
  description = "Use this ARN if you already have a MediaConvert queue."
  type        = string
  default     = null
}

# CloudWatch Logs
variable "lambda_log_retention_days" {
  description = "Retention in days for Lambda log group."
  type        = number
  default     = 7
}
