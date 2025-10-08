variable "tags" { type = map(string) }

# เลือก subnet ได้ 2 ทาง: (1) subnet_id ตรงๆ หรือ (2) subnet_key + subnet_tier
variable "instances" {
  description = "Map ของ EC2 ที่จะสร้าง (key = ชื่อ logical); ระบุ subnet ด้วย subnet_id หรือ subnet_key+subnet_tier"
  type = map(object({
    name                = string
    instance_type       = optional(string, "t3.micro")
    subnet_id           = optional(string)
    subnet_key          = optional(string)
    security_group_ids  = optional(list(string), [])
    associate_public_ip = optional(bool, true)
    extra_tags          = optional(map(string), {})
    db_host_override    = optional(string)
    db_port_override    = optional(string)
    db_name_override    = optional(string)
    enable_webapp       = optional(bool, false) //if true, it will install web
    master_secret_arn   = optional(string)      //if enable_webapp=true, this must be non-null
  }))
}

# subnet id map from network module
variable "subnet_id_map" { type = map(string) }
# default sg ( module.security.sg_id_no_inbound)
variable "default_security_group_id" { type = string }


