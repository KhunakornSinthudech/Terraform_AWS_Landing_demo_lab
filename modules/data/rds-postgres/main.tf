locals {
  families = { for k, v in var.instances : k => (can(regex("^16(\\.|$)", v.engine_version)) ? "postgres16" : "postgres15") }
}




resource "aws_db_subnet_group" "this" {
  for_each   = var.instances
  name       = "${each.value.db_identifier}-subnets"
  subnet_ids = [for k, v in var.subnet_id_map : v if contains(each.value.subnet_keys, k)]
  tags       = merge(var.tags, { Name = "${each.value.db_identifier}-subnets" })
}

resource "aws_security_group" "db" {
  for_each    = var.instances
  name        = "${each.value.db_identifier}-db-sg"
  description = "sg for db instance"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${each.value.db_identifier}-db-sg" })
}

resource "aws_security_group_rule" "ingress_app" {
  for_each                 = var.instances
  type                     = "ingress"
  security_group_id        = aws_security_group.db[each.key].id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.app_sg_id
  description              = "Allow Postgres from app SG"
}

  # Create a rule for each allowed_cidr per instance
resource "aws_security_group_rule" "ingress_cidr" {
  for_each = {
    for pair in flatten([
      for inst_key, inst in var.instances : [
        for cidr in var.allowed_cidrs : {
          key = "${inst_key}-${cidr}"
          instance_key = inst_key
          cidr         = cidr
        }
      ]
    ]) : pair.key => {
      instance_key = pair.instance_key
      cidr         = pair.cidr
    }
  }
  type             = "ingress"
  security_group_id= aws_security_group.db[each.value.instance_key].id
  from_port        = 5432
  to_port          = 5432
  protocol         = "tcp"
  cidr_blocks      = [each.value.cidr]
  description      = "TEMP: allow from CIDR for testing"
}

resource "aws_security_group_rule" "egress_all" {
  for_each          = var.instances
  type              = "egress"
  security_group_id = aws_security_group.db[each.key].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all egress (RDS-managed traffic)"
}



resource "aws_db_parameter_group" "pg" {
  for_each = var.instances
  name   = "${each.value.db_identifier}-params-v${var.pg_version}"
  family = local.families[each.key]
  tags   = merge(var.tags, { Name = "${each.value.db_identifier}-params" })
  parameter {
    name  = "rds.force_ssl"
    value = "1"
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
    apply_method = "immediate"
  }
}

resource "aws_db_instance" "pg" {
  for_each                = var.instances
  identifier              = each.value.db_identifier
  db_name                 = each.value.db_name
  username                = each.value.db_username

  engine                  = "postgres"
  engine_version          = each.value.engine_version
  instance_class          = each.value.instance_class
  allocated_storage       = each.value.allocated_storage
  multi_az                = each.value.multi_az
  backup_retention_period = each.value.backup_retention_period

  db_subnet_group_name    = aws_db_subnet_group.this[each.key].name
  vpc_security_group_ids  = [aws_security_group.db[each.key].id]
  publicly_accessible     = each.value.publicly_accessible
  deletion_protection     = false
  skip_final_snapshot     = true
  auto_minor_version_upgrade = true
  apply_immediately       = true //true in prod
  performance_insights_enabled = true
  parameter_group_name    = aws_db_parameter_group.pg[each.key].name
  maintenance_window      = "Mon:18:00-Mon:19:00"
  backup_window           = "19:00-20:00"

  # RDS-managed secret 
  manage_master_user_password   = true // let RDS manage the secret in Secrets Manager to prevent password mismatch and rotation issue ; prevent expose password in tfstate
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id // null for default AWS-managed key
  tags = merge(var.tags, { Name = each.value.db_identifier })
}



// go to rds manage secret instead for lab
// these code was using random password and store in secrets manager for production use if needed
// risky to password mismatch if change manually and bad rotation practice
// keep it to use with app user with limited permission !!!!! next step to go.!!!!!

# resource "random_password" "db" {
#   for_each         = var.instances
#   length           = 24
#   special          = true
#   override_special = "!#%^*-_=+"
#   min_lower     = 1
#   min_upper     = 1
#   min_numeric   = 1
#   min_special   = 1
# }

# resource "aws_secretsmanager_secret" "db" {
#   for_each = var.instances
#   name = "${each.value.db_identifier}-credentials-dev1"
#   recovery_window_in_days = 7
#   tags = merge(var.tags, { Name = "${each.value.db_identifier}-credentials" })
# }

# resource "aws_secretsmanager_secret_version" "db" {
#   for_each     = var.instances
#   secret_id     = aws_secretsmanager_secret.db[each.key].id
#   secret_string = jsonencode({
#     username = each.value.db_username
#     password = random_password.db[each.key].result
#     engine   = "postgres"
#   })
# }

# resource "aws_db_instance" "pg" {
#   for_each                = var.instances
#   identifier              = each.value.db_identifier
#   db_name                 = each.value.db_name
#   username                = each.value.db_username
#   engine                  = "postgres"
#   engine_version          = each.value.engine_version
#   instance_class          = each.value.instance_class
#   allocated_storage       = each.value.allocated_storage
#   multi_az                = each.value.multi_az
#   backup_retention_period = each.value.backup_retention_period
#   db_subnet_group_name    = aws_db_subnet_group.this[each.key].name
#   vpc_security_group_ids  = [aws_security_group.db[each.key].id]
#   publicly_accessible     = var.publicly_accessible
#   deletion_protection     = false
#   skip_final_snapshot     = true
#   auto_minor_version_upgrade = true
#   apply_immediately       = true
#   performance_insights_enabled = true
#   parameter_group_name    = aws_db_parameter_group.pg[each.key].name
#   maintenance_window      = "Mon:18:00-Mon:19:00"
#   backup_window           = "19:00-20:00"
#   tags = merge(var.tags, { Name = each.value.db_identifier })
# }