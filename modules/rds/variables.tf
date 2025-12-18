variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "allowed_sg_id" {
  type    = string
  default = null
}

variable "allocated_storage" {
  type    = number
  default = 10
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "engine" {
  type    = string
  default = "mysql"
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "username" {
  type    = string
}

variable "password" {
  type    = string
  sensitive = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}