# ---- Collect inputs ----------------------------------------------------------
# all ARNs (may be unknown at plan; nulls removed)
locals {
  master_secret_arns = distinct(compact([
    for v in values(var.instances) : try(v.master_secret_arn, null)
  ]))

  # true if any instance enables webapp (this should be known at plan)
  any_enable_webapp = anytrue([
    for v in values(var.instances) : try(v.enable_webapp, false)
  ])
}

# ---- Policy doc + policy + attachment (count depends on a known boolean) ----
data "aws_iam_policy_document" "sm_access" {
  count = local.any_enable_webapp ? 1 : 0
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = local.master_secret_arns
  }
}

resource "aws_iam_policy" "sm_access" {
  count  = local.any_enable_webapp ? 1 : 0
  name   = "compute-sm-access"
  policy = data.aws_iam_policy_document.sm_access[0].json

  # Ensure we don't end up with an empty Resource list at apply
  lifecycle {
    precondition {
      condition     = length(local.master_secret_arns) > 0
      error_message = "enable_webapp=true but no master_secret_arn provided/resolved. Create RDS first or pass the ARN."
    }
  }
}

resource "aws_iam_role_policy_attachment" "attach_sm" {
  count     = local.any_enable_webapp ? 1 : 0
  role      = aws_iam_role.ssm_ec2.name
  policy_arn= aws_iam_policy.sm_access[0].arn
}
