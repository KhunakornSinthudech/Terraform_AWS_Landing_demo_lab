
variable "region"                 { type = string }
variable "vpc_cidr"               { type = string }
variable "tags"                   { type = map(string) }
variable "destination_cidr_block" { type = string }
variable "media_enabled" { type = bool }




variable "public_subnets" {
  type = map(object({
    cidr_block         = string
    availability_zone  = string
    create_nat_gateway = optional(bool, false)
  }))
}

variable "private_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "ec2_instances" {
  type = map(object({
    name               = string
    instance_type      = optional(string, "t3.micro")
    subnet_id          = optional(string)
    subnet_key         = optional(string) # ["private/a","public/b"]
    security_group_ids = optional(list(string),[]) #sg ids
    associate_public_ip= optional(bool, true)
    extra_tags         = optional(map(string), {})
    db_host_override  = optional(string)
    db_port_override  = optional(string)
    db_name_override  = optional(string)
    enable_webapp     = optional(bool, false) //if true, it will install web
    master_secret_arn = optional(string) //if enable_webapp=true, this must be non-null
  }))
}

variable "rds_instances" {
  description = "Map of RDS instance configurations. Each key is an instance name."
  type = map(object({
    db_identifier           = string
    db_name                 = string
    db_username             = string
    engine_version          = string
    instance_class          = string
    allocated_storage       = number
    multi_az                = bool
    backup_retention_period = number
    publicly_accessible     = bool
    allowed_cidrs           = list(string)
    subnet_keys              = list(string) # ["private/a","public/b"]
  })) 
}

variable "pg_version" {
  type        = number
  default     = 1
  description = "Bump เวอร์ชันเมื่อแก้ static params เพื่อสร้าง Parameter Group ใหม่"
  
}



