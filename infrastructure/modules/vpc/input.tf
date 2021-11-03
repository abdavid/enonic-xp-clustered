variable "private" {
  type    = bool
  default = false
}

variable "network" {
  type = string
}

variable "vpc_name" {
  type    = string
  default = "vpc"
}

variable "map_public_ip" {
  type    = bool
  default = true
}
