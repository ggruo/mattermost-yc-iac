variable "name" {
  type = string
}

variable "network_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "zone" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "preset" {
  type = string
}
variable "password" {
  type      = string
  sensitive = true
}
