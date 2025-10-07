//local default config for CloudWatch Agent supply var.config_override_json to override in raw JSON
locals {
  default_config = {
    agent = { metrics_collection_interval = 60 } //every minutes
    metrics = {
      namespace         = var.namespace //namespace for lab
      append_dimensions = {
        "InstanceId"   : "$${aws:InstanceId}"
        "InstanceType" : "$${aws:InstanceType}"
      }
      metrics_collected = {
        cpu  = { resources=["*"], totalcpu=true, measurement=["cpu_usage_idle","cpu_usage_user","cpu_usage_system"] }
        mem  = { measurement=["mem_used_percent"] }
        disk = { resources=["/"], measurement=["used_percent"] }
      }
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path = "/var/log/messages"
              log_group_name = var.log_group_name
              log_stream_name = "{instance_id}"
              timezone = "UTC"
            },
            {
              file_path = "/var/log/oaktestwebapp.log"
              log_group_name = var.log_group_name
              log_stream_name = "{instance_id}-webapp"
              timezone = "UTC"
            }
          ]
        }
      }
    }
  }

  config_payload = var.config_override_json != "" ? var.config_override_json : jsonencode(local.default_config) //override with user JSON if provided
  kms_opt        = var.kms_key_id != "" ? var.kms_key_id : null
  ssm_parameter_name = "/AmazonCloudWatch/linux" 
}


# Attach CloudWatchAgentServerPolicy role to the IAM role of ec2
resource "aws_iam_role_policy_attachment" "cw_agent" {
  count      = var.enabled ? 1 : 0
  role       = var.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Log group for system logs with retention
resource "aws_cloudwatch_log_group" "system" {
  count             = var.enabled ? 1 : 0
  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_opt
}

# Store agent config in SSM Parameter
resource "aws_ssm_parameter" "cw_config" {
  count = var.enabled ? 1 : 0
  name  = local.ssm_parameter_name
  type  = "String"
  value = local.config_payload
}


#All-in-one: CW install config restart
    // failfast with euo pipefail
    // check if ec2 is RPM based 
    // yum cloudwatch-agent if not installed
    // else check if DPKG based
    // apt-get cloudwatch-agent if not installed
    // then fetch config from SSM and start the agent
resource "aws_ssm_association" "cwagent_all_in_one" {
  name = "AWS-RunShellScript"

  targets {
        key    = var.target_key
        values = var.target_values
  }

  parameters = {
    commands = <<-EOT
      #!/bin/bash
      set -euo pipefail 
      if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y amazon-cloudwatch-agent || true
        sudo dnf install -y rsyslog && sudo systemctl enable --now rsyslog
      elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y amazon-cloudwatch-agent || true
        sudo yum install -y rsyslog && sudo systemctl enable --now rsyslog
      elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y amazon-cloudwatch-agent || true
        sudo apt-get install -y rsyslog && sudo systemctl enable --now rsyslog
      fi

      /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${aws_ssm_parameter.cw_config[0].name} -s 
      sudo systemctl enable --now amazon-cloudwatch-agent     
    EOT
  }
  
  apply_only_at_cron_interval = false
  compliance_severity         = "LOW"
}



# these broken as racing between install and configure; use all-in-one above

# # Install CloudWatch Agent via SSM Distributor
# resource "aws_ssm_association" "install_cwagent" {
#   count = var.enabled ? 1 : 0
#   name  = "AWS-ConfigureAWSPackage"
#   parameters = {
#     action = "Install"
#     name   = "AmazonCloudWatchAgent"
#   }
#   targets {
#     key    = var.target_key
#     values = var.target_values
#   }
#   apply_only_at_cron_interval = false
# }

# # Configure + start CloudWatch Agent using the SSM parameter
# resource "aws_ssm_association" "configure_cwagent" {
#   count = var.enabled ? 1 : 0
#   name  = "AmazonCloudWatch-ManageAgent"
#   parameters = {
#     action                        = "configure"
#     mode                          = "ec2"
#     optionalConfigurationSource   = "ssm"
#     optionalConfigurationLocation = aws_ssm_parameter.cw_config[0].name
#     optionalRestart               = "yes"
#   }
#   targets {
#     key    = var.target_key
#     values = var.target_values
#   }
#   depends_on = [
#     aws_ssm_association.install_cwagent,
#     aws_cloudwatch_log_group.system,
#     aws_iam_role_policy_attachment.cw_agent
#   ]
# }