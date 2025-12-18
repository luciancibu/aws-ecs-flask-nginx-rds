variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_sg_id" {
  type    = string
  default = null
}

variable "aws_region" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "db_host" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}
