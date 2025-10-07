region                 = "ap-southeast-1"
vpc_cidr               = "10.0.0.0/16"
destination_cidr_block = "0.0.0.0/0"

tags = { env = "dev", app = "landing_zone_lab", owner = "Khunakorn" }

public_subnets = {
  a = { cidr_block = "10.0.1.0/24", availability_zone = "ap-southeast-1a", create_nat_gateway = false }
  b = { cidr_block = "10.0.2.0/24", availability_zone = "ap-southeast-1b", create_nat_gateway = false }
  c = { cidr_block = "10.0.3.0/24", availability_zone = "ap-southeast-1c", create_nat_gateway = false }
}

private_subnets = {
  a = { cidr_block = "10.0.51.0/24", availability_zone = "ap-southeast-1a" }
  b = { cidr_block = "10.0.52.0/24", availability_zone = "ap-southeast-1b" }
  c = { cidr_block = "10.0.53.0/24", availability_zone = "ap-southeast-1c" }
}

#instances to create
ec2_instances = {
  app_b = {
    name          = "app-b"
    subnet_key    = "public/b"
    instance_type = "t3.micro"
  }
  # # private instance without public IP
  # worker_a = {
  #   name            = "worker-a"
  #   subnet_key      = "private/a"
  #   instance_type   = "t3.micro"
  #   associate_public_ip = false
  # }
}


#rds instances
rds_instances = {
  # fail_test = {
  #   db_identifier          = "oak-lab-rds-db-pg-public"
  #   db_name                = "landingzonedb"
  #   db_username            = "lzadmin"
  #   engine_version         = "16.3"
  #   instance_class         = "db.t4g.micro"
  #   allocated_storage      = 20
  #   backup_retention_period= 7
  #   subnet_keys             = ["public/a","public/b"] //at least 2 subnets for multi-az
  #   multi_az               = false //false for dev/test
  #   publicly_accessible    = true //should be failed by iam policy
  #   allowed_cidrs         = []//test cidr from home ["x.x.x.x/32"]
  # }
  rdsdb_webapp_demo = {
    db_identifier           = "oak-lab-rds-db-pg-private"
    db_name                 = "landingzonedb"
    db_username             = "lzadmin"
    engine_version          = "16.3"
    instance_class          = "db.t4g.micro"
    allocated_storage       = 20
    backup_retention_period = 7
    subnet_keys             = ["private/a", "private/b"] //at least 2 subnets for multi-az
    multi_az                = false                      //false for dev/test
    publicly_accessible     = false
    allowed_cidrs           = [] //test cidr from home ["x.x.x.x/32"]
  }
}

media_enabled = false