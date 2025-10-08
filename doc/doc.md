# get ami list
- aws ssm get-parameters-by-path --path /aws/service/ami-amazon-linux-latest --query Parameters[].Name
- https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html?utm_source=chatgpt.com


# subscribe media convert
add role mediaconvert:DescribeEndpoints
aws mediaconvert describe-endpoints --max-results 1 --region ap-southeast-1

# config backend
terraform init -backend-config='backend.hcl'  -migrate-state
terraform init -backend-config='backend.hcl' -reconfigure

# fmt diff fix if edit on local

terraform fmt -recursive
git add -A
git commit -m "fmt: canonical spacing"

