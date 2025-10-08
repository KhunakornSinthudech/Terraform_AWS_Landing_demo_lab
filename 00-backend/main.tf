locals {
  bucket_name = coalesce(var.tf_state_bucket_name, "${var.project}-tfstate-${var.region}")
  table_name  = coalesce(var.tf_lock_table_name, "${var.project}-tf-locks")
}

# --- S3 bucket for remote state ---
resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = false # ป้องกันลบ state ง่ายเกินไป
  tags = {
    Name    = local.bucket_name
    Project = var.project
    Purpose = "terraform-state"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning = สำคัญมากเวลา rollback state
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.use_kms ? "aws:kms" : "AES256"
      kms_master_key_id = var.use_kms ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.use_kms
  }
}

# Enforce TLS (deny if no HTTPS)
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

# --- DynamoDB table for state lock ---
resource "aws_dynamodb_table" "lock" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery { enabled = true }

  tags = {
    Name    = local.table_name
    Project = var.project
    Purpose = "terraform-lock"
  }
}
