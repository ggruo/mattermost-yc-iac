variable "name_prefix" { type = string }
variable "network_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "zones" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "postgres_version" { type = string }
variable "resource_preset_id" { type = string }
variable "disk_type_id" { type = string }
variable "disk_size" { type = number }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "backup_retain_period_days" { type = number }
