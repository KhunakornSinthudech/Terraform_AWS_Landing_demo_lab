variable "enabled" {
  description = "Enable/disable this module."
  type        = bool
  default     = true
}

variable "iam_role_name" {
  type = string
}

variable "target_key" {
  description = "SSM association target key (e.g., 'tag:Name')."
  type        = string
  default     = "tag:Name"
}

variable "target_values" {
  description = "SSM association target values (e.g., ['bastion-ssm'])."
  type        = list(string)
  default     = ["bastion-ssm"]
}

variable "log_group_name" {
  description = "CloudWatch Logs group to write system logs to."
  type        = string
  default     = "/lz/dev/messages"
}

variable "retention_in_days" {
  description = "Log retention in days."
  type        = number
  default     = 7
}

variable "kms_key_id" {
  description = "Optional KMS key id/arn for log group encryption (leave empty to skip)."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Custom CloudWatch metrics namespace for the agent."
  type        = string
  default     = "Demo/LZ"
}

variable "config_override_json" {
  description = "Optional full JSON for CloudWatch agent config. If non-empty, overrides default config."
  type        = string
  default     = ""
}