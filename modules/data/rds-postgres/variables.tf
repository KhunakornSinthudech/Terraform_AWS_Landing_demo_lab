variable "vpc_id" { type = string }
variable "app_sg_id" { type = string }
variable "instances" {
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
    subnet_keys             = list(string) # ["private/a","public/b"] 
  }))
}
variable "allowed_cidrs" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}


variable "subnet_id_map" {
  type = map(string) #  {"private/a"="subnet-123", ...}
}

# รับ map ของ subnet id จากโมดูล network
variable "public_subnet_ids_by_key" { type = map(string) }
variable "private_subnet_ids_by_key" { type = map(string) }

variable "pg_version" {
  type        = number
  default     = 2
  description = "Bump เวอร์ชันเมื่อแก้ static params เพื่อสร้าง Parameter Group ใหม่"
}

variable "master_user_secret_kms_key_id" {
  type        = string
  default     = null
  description = "KMS Key ARN/ID - RDS master secret with customer-managed key"
}