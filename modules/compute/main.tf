# AMI  AL2023 x86_64
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-x86_64"]
  }
}

# IAM role for SSM
resource "aws_iam_role" "ssm_ec2" {
  name = "ssm-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
# 3 steps to allow EC2 to be managed by SSM using profile attavhment
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ssm_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_instance_profile" "ssm" {
  name = "ssm-ec2-instance-profile"
  role = aws_iam_role.ssm_ec2.name
}

# load webapp template
data "template_file" "webapp_py" {
  template = file("${path.module}/templates/webapp/app.py.tmpl")
}

# multi instances
resource "aws_instance" "this" {

  # validate input: if enable_webapp=true, master_secret_arn must be non-null
  # bug fix for iam-secrets.tf precondition not working with try() that returns null
  lifecycle {
    precondition {
      condition     = !(try(each.value.enable_webapp, false) && try(each.value.master_secret_arn, null) == null)
      error_message = "Instance ${each.key}: enable_webapp=true requires master_secret_arn (non-null)."
    }
  }


  for_each      = var.instances
  ami           = data.aws_ami.al2023.id
  instance_type = try(each.value.instance_type, "t3.micro")
  subnet_id     = var.subnet_id_map[try(each.value.subnet_key, "")]

  vpc_security_group_ids      = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : [var.default_security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = try(each.value.associate_public_ip, true)
  tags                        = merge(var.tags, { Name = each.value.name })
  //webapp template application
  user_data = try(each.value.enable_webapp, false) ? templatefile("${path.module}/templates/webapp/webapp_env.sh.tmpl",
    {
      master_secret_arn = try(each.value.master_secret_arn, "")
      db_host_override  = try(each.value.db_host_override, "")
      db_port_override  = try(each.value.db_port_override, "")
      db_name_override  = try(each.value.db_name_override, "")
      app_py            = data.template_file.webapp_py.rendered
    }
  ) : templatefile("${path.module}/templates/ssmagent_only.sh.tmpl", {})

  root_block_device {
    volume_size           = 5 #2gb got error on install cw agent 
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # ให้แนบ policy เสร็จก่อน ค่อยสร้าง EC2 (กัน race ตอนดึง secret)
  user_data_replace_on_change = true
  depends_on                  = [aws_iam_role_policy_attachment.attach_sm]
}

### legacy single instance (commented out) ###

# //define the latest Amazon Linux 2023 AMI for ARM64 architecture
# data "aws_ami" "al2023" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter { 
#     name = "name"
#     //values = ["al2023-ami-*-arm64"] 
#     values = ["al2023-ami-*-x86_64"] 
#    }
# }

# ###  SSM profile for EC2 instances ###
# //create IAM role for EC2 to allow SSM to manage the instance
# resource "aws_iam_role" "ssm_ec2" {
#   name               = "ssm-ec2-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{Effect="Allow", Principal={Service="ec2.amazonaws.com"}, Action="sts:AssumeRole"}]
#   })
# }
# //give AmazonSSMManagedInstanceCore policy to the role above
# resource "aws_iam_role_policy_attachment" "ssm_core" {
#   role       = aws_iam_role.ssm_ec2.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }
# //create instance profile for the role above for EC2 to use it when launch
# resource "aws_iam_instance_profile" "ssm" {
#   name = "ssm-ec2-profile"
#   role = aws_iam_role.ssm_ec2.name
# }
# #############################

# resource "aws_instance" "oaklab_ec2_ssm" {
#   ami                         = data.aws_ami.al2023.id
#   instance_type               = var.instance_type
#   subnet_id                   = var.subnet_id
#   vpc_security_group_ids      = [var.security_group_id]
#   iam_instance_profile        = aws_iam_instance_profile.ssm.name //bind the instance profile to the EC2
#   associate_public_ip_address = true
#   tags = merge(var.tags, { Name = var.name }) //merge tags from var and add Name tag
# }