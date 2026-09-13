variable "folder_id" {
  type = string
}
variable "zone" {
  type    = string
  default = "ru-central1-a"
}
variable "trusted_cidrs" {
  description = "Administrator public IPv4 CIDRs, normally a single /32."
  type        = list(string)
  validation {
    condition     = length(var.trusted_cidrs) > 0 && alltrue([for c in var.trusted_cidrs : can(cidrnetmask(c)) && !endswith(c, "/0")])
    error_message = "Supply trusted IPv4 CIDRs; /0 is forbidden."
  }
}
variable "postgres_password" {
  type      = string
  sensitive = true
}
variable "postgres_preset" {
  type    = string
  default = "s3-c2-m8"
}
variable "ssh_public_key_path" {
  type = string
}
variable "fqdn" {
  description = "Delegated lab hostname, e.g. vm.lab.example.org"
  type        = string
}
variable "dns_zone_id" {
  description = "Existing Cloud DNS zone created during lab 0"
  type        = string
}
variable "vm_cores" {
  type    = number
  default = 2
}
variable "vm_memory" {
  type    = number
  default = 2
}
