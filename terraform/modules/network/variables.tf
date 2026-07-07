variable "name_prefix" { type = string }
variable "zones" { type = list(string) }
variable "subnet_cidrs" { type = list(string) }
variable "domain_name" { type = string }
variable "mattermost_fqdn" { type = string }
variable "create_dns_zone" { type = bool }
variable "dns_zone_id" {
  type    = string
  default = null
}
