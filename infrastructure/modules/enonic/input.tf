data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

variable "instances" {
  type = map(any)
}

variable "enabled_azs" {
  type = list(any)
}

variable "enonic_ami" {
  type = string
}


variable "enonic_docker_image" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type = string
}

variable "lb_subnets" {
  type = list(string)
}

variable "storage_size" {
  type    = number
  default = 10
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "healthcheck_path" {
  type    = string
  default = "/server"
}

variable "healthcheck_port" {
  type    = number
  default = 2609
}

variable "grace_period" {
  type    = number
  default = 300
}

variable "log_group" {
  type    = string
  default = "/apps/enonic-xp"
}

variable "app_name" {
  type    = string
  default = "enonic-xp"
}

variable "enonic_repo" {
  type = object({
    name       = string,
    account_id = string,
    region     = string,
  })
}
