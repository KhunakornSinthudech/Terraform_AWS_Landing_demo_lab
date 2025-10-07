variable "vpc_cidr" { type = string }
variable "tags" {  type = map(string) }
variable "region" { type = string }
variable "destination_cidr_block" { type = string }

variable "public_subnets" {
type = map(object({ 
    cidr_block = string, 
    availability_zone = string, 
    create_nat_gateway = optional(bool, false) 
  }))
}

variable "private_subnets" {
  type = map(object({ 
    cidr_block = string, 
    availability_zone = string 
  }))
}
