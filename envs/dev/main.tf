locals {
  subnet_id_map = merge(
    { for k, v in module.network.public_subnet_ids_by_key : "public/${k}" => v },
    { for k, v in module.network.private_subnet_ids_by_key : "private/${k}" => v }
  )
}

module "network" {
  source                 = "../../modules/network"
  vpc_cidr               = var.vpc_cidr
  tags                   = var.tags
  public_subnets         = var.public_subnets
  private_subnets        = var.private_subnets
  region                 = var.region
  destination_cidr_block = var.destination_cidr_block
}

module "security" {
  source = "../../modules/security"
  vpc_id = module.network.vpc_id
  tags   = var.tags
}

module "compute" {
  source        = "../../modules/compute"
  tags          = var.tags
  subnet_id_map = local.subnet_id_map
  // push subnet ids from network module output to compute module input
  // default sg as no inbound rule
  default_security_group_id = module.security.sg_id_no_inbound
  // instances to build
  instances = merge(
    var.ec2_instances,
    {
      web_rds_demo = {
        name               = "oaklab-pg-rds-web"
        subnet_key         = "public/a"
        instance_type      = "t3.micro"
        security_group_ids = [module.security.web_sg_id] //web sg from security module
        enable_webapp      = true
        master_secret_arn  = module.rds.db_master_secret_arn["rdsdb_webapp_demo"] // RDS secret for webapp to connect to db
        db_host_override   = module.rds.db_host["rdsdb_webapp_demo"]              // it only sent username and password by default
        db_port_override   = module.rds.db_port["rdsdb_webapp_demo"]              // it only sent username and password by default
        db_name_override   = module.rds.db_name["rdsdb_webapp_demo"]              // it only sent username and password by default
      }
    }
  )
}


#cloudwatch injection - modify to use all instance from compute module
module "observe" {
  source        = "../../modules/observe"
  iam_role_name = module.compute.iam_role_name
  target_key    = "tag:Name"
  target_values = module.compute.instance_names   //tag Name of every instance from compute module output
  namespace     = "oaklab/LZdemo/RDS-EC2(webapp)" //namespace for lab
}

module "rds" {
  source                    = "../../modules/data/rds-postgres"
  vpc_id                    = module.network.vpc_id
  public_subnet_ids_by_key  = module.network.public_subnet_ids_by_key
  private_subnet_ids_by_key = module.network.private_subnet_ids_by_key
  subnet_id_map             = local.subnet_id_map
  app_sg_id                 = module.security.web_sg_id //sg id of test wevb server
  # Provide instances as a list/object as required by the module
  instances = var.rds_instances
  tags      = var.tags
}


module "media_converter" {
  source  = "../../modules/Media"
  project = "oak-lab-demo-video2"
  tags    = var.tags
  # region  = var.region 

  # Buckets: create new (default true). To reuse existing, set create_buckets=false and provide names.
  create_buckets       = true
  bucket_force_destroy = true       // allow destroy non-empty for Oak lab demo only
  input_bucket_name    = null       // set to someting to not use default name
  output_bucket_name   = null       // set to someting to not use default name
  input_prefix         = "input/"   # upload files here to trigger convert
  output_prefix        = "outputs/" # results will be written here
  queue_name           = null       // set to someting to not use default name
  create_queue         = false      // create new queue 
  existing_queue_arn   = "placeholder"  // provide existing queue ARN here if "create_queue=false"
}


# old observe module
# //cloud watch injection
# module "observe" {
#   source            = "../../modules/observe"
#   enabled           = true
#   iam_role_name     = module.compute.iam_role_name  // IAM role of my EC2 instance in public subnet ; use output from compute module
#   target_key        = "tag:Name"
#   target_values     =  var.instances.name // ["oaklab_ec2_ssm"]                 // my EC2 instance Name tag
#   log_group_name    = "/lz/dev/messages"
#   retention_in_days = 7
#   namespace         = "oaklab/dev/landingzonedemo" //namespace for lab
#   kms_key_id        = "" //optional KMS key for encrypt log group; empty for default
#   //config_override_json = file("${path.module}/cwagent.json")
# }