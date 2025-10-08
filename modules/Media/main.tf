
locals {
  #region = var.region
  # Default bucket names when creating
  default_input_bucket_name  = "${var.project}-mc-input"
  default_output_bucket_name = "${var.project}-mc-output"
}

# S3 buckets (create or use existing)
resource "aws_s3_bucket" "input" {
  count         = var.create_buckets ? 1 : 0
  bucket        = var.input_bucket_name != null ? var.input_bucket_name : local.default_input_bucket_name
  force_destroy = var.bucket_force_destroy
  tags          = merge(var.tags, { Name = "${var.project}-mc-input" })
}
resource "aws_s3_bucket" "output" {
  count         = var.create_buckets ? 1 : 0
  bucket        = var.output_bucket_name != null ? var.output_bucket_name : local.default_output_bucket_name
  force_destroy = var.bucket_force_destroy
  tags          = merge(var.tags, { Name = "${var.project}-mc-output" })
}

# When using existing buckets, lookup by name
data "aws_s3_bucket" "input" {
  count  = var.create_buckets ? 0 : 1
  bucket = var.input_bucket_name
}

data "aws_s3_bucket" "output" {
  count  = var.create_buckets ? 0 : 1
  bucket = var.output_bucket_name
}

# Normalized bucket IDs/ARNs
# it will auto select from created or existing based on var.create_buckets check by [0] index (lazy check)
locals {
  input_bucket_id   = var.create_buckets ? aws_s3_bucket.input[0].id : data.aws_s3_bucket.input[0].id
  input_bucket_arn  = var.create_buckets ? aws_s3_bucket.input[0].arn : data.aws_s3_bucket.input[0].arn
  output_bucket_id  = var.create_buckets ? aws_s3_bucket.output[0].id : data.aws_s3_bucket.output[0].id
  output_bucket_arn = var.create_buckets ? aws_s3_bucket.output[0].arn : data.aws_s3_bucket.output[0].arn
}

# resource "null_resource" "mediaconvert_subscribe" {
#   provisioner "local-exec" {
#     command = "aws --region ${var.region} mediaconvert describe-endpoints --max-results 1 >/dev/null"
#   }
# }



# role assigned to MediaConvert service trust
data "aws_iam_policy_document" "mc_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "mc_service_role" {
  name               = "${var.project}-mediaconvert-role"
  assume_role_policy = data.aws_iam_policy_document.mc_trust.json
  tags               = var.tags
}

# role assigned to MediaConvert service - S3 access + CloudWatch logs
data "aws_iam_policy_document" "mc_access" {
  statement {
    sid     = "ReadInput"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      local.input_bucket_arn,
      "${local.input_bucket_arn}/*"
    ]
  }
  statement {
    sid     = "WriteOutput"
    actions = ["s3:PutObject", "s3:PutObjectAcl", "s3:ListBucket"]
    resources = [
      local.output_bucket_arn,
      "${local.output_bucket_arn}/*"
    ]
  }
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "mc_access" {
  name   = "${var.project}-mediaconvert-access"
  policy = data.aws_iam_policy_document.mc_access.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "mc_attach" {
  role       = aws_iam_role.mc_service_role.name
  policy_arn = aws_iam_policy.mc_access.arn
}


# Lambda assume role
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"] // allow lambda to assume this role
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lambda_role" {
  name               = "${var.project}-lambda-mediaconvert-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = var.tags
}

# Lambda permissions: CreateJob, DescribeEndpoints, GetJob + PassRole to MediaConvert service role
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid       = "MediaConvertControl"
    actions   = ["mediaconvert:CreateJob", "mediaconvert:DescribeEndpoints", "mediaconvert:GetJob"]
    resources = ["*"]
  }
  statement {
    sid       = "PassMediaConvertRole"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.mc_service_role.arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["mediaconvert.amazonaws.com"]
    }
  }
  statement {
    sid     = "ReadInputBucket"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      local.input_bucket_arn,
      "${local.input_bucket_arn}/*"
    ]
  }
  statement {
    sid       = "LambdaLogs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${var.project}-lambda-mediaconvert-access"
  policy = data.aws_iam_policy_document.lambda_policy.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

##### test
# MediaConvert queue (create or use existing)
resource "aws_media_convert_queue" "main" {
  count        = var.create_queue ? 1 : 0
  name         = coalesce(var.queue_name, "${var.project}-mc-queue")
  description  = "MediaConvert queue for ${var.project}"
  pricing_plan = "ON_DEMAND"
  #depends_on = [null_resource.mediaconvert_subscribe]
  tags = var.tags
}
# Use existing queue ARN if not creating
locals {
  queue_arn = var.create_queue ? aws_media_convert_queue.main[0].arn : var.existing_queue_arn // must be provided if not creating
}

# Package lambda from local file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/mc_submit.zip"
}

resource "aws_lambda_function" "mc_submit" {
  function_name = "${var.project}-mc-submit-job"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.main"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      INPUT_BUCKET  = local.input_bucket_id
      OUTPUT_BUCKET = local.output_bucket_id
      INPUT_PREFIX  = var.input_prefix
      OUTPUT_PREFIX = var.output_prefix
      QUEUE_ARN     = local.queue_arn
      SERVICE_ROLE  = aws_iam_role.mc_service_role.arn
      #AWS_REGION    = var.region
    }
  }

  tags = var.tags
}

#  log retention for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.mc_submit.function_name}"
  retention_in_days = var.lambda_log_retention_days
  tags              = var.tags
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mc_submit.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = local.input_bucket_arn
}

# S3 notification: trigger Lambda on new objects under input_prefix
resource "aws_s3_bucket_notification" "input_events" {
  bucket = local.input_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.mc_submit.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.input_prefix
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
