variable "project_name" {
  description = "Project name used as a prefix for Yandex Cloud resources."
  type        = string
  default     = "mattermost"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "prod"
}

variable "zone" {
  description = "Default Yandex Cloud availability zone."
  type        = string
  default     = "ru-central1-a"
}

variable "zones" {
  description = "Availability zones used for subnets and PostgreSQL hosts. Use at least two zones for production HA."
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets. Must have the same length as zones."
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.20.0/24"]
}

variable "trusted_ssh_cidrs" {
  description = "CIDR blocks allowed to connect to the VM over SSH."
  type        = list(string)
}

variable "ssh_username" {
  description = "Linux user created by cloud-init for SSH access."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key injected into the VM."
  type        = string
}

variable "vm_platform_id" {
  description = "Yandex Compute platform ID."
  type        = string
  default     = "standard-v3"
}

variable "vm_cores" {
  description = "Number of VM vCPU cores."
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "VM memory in GB."
  type        = number
  default     = 4
}

variable "vm_core_fraction" {
  description = "Baseline vCPU performance percentage."
  type        = number
  default     = 100
}

variable "vm_boot_disk_size" {
  description = "VM boot disk size in GB."
  type        = number
  default     = 30
}

variable "vm_image_family" {
  description = "Public image family for the VM."
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "domain_name" {
  description = "DNS zone name, for example example.com."
  type        = string
}

variable "mattermost_fqdn" {
  description = "Mattermost public FQDN, for example mattermost.example.com."
  type        = string
}

variable "create_dns_zone" {
  description = "Whether Terraform should create a Cloud DNS public zone."
  type        = bool
  default     = true
}

variable "dns_zone_id" {
  description = "Existing Cloud DNS zone ID when create_dns_zone is false."
  type        = string
  default     = null
}

variable "postgres_version" {
  description = "Managed PostgreSQL major version."
  type        = string
  default     = "17"
}

variable "postgres_resource_preset_id" {
  description = "Managed PostgreSQL host class."
  type        = string
  default     = "s3-c2-m8"
}

variable "postgres_disk_type_id" {
  description = "Managed PostgreSQL disk type."
  type        = string
  default     = "network-ssd"
}

variable "postgres_disk_size" {
  description = "Managed PostgreSQL disk size in GB."
  type        = number
  default     = 20
}

variable "postgres_db_name" {
  description = "Mattermost PostgreSQL database name."
  type        = string
  default     = "mattermost"
}

variable "postgres_user" {
  description = "Mattermost PostgreSQL username."
  type        = string
  default     = "mattermost"
}

variable "postgres_password" {
  description = "Mattermost PostgreSQL password. Pass with TF_VAR_postgres_password or a secure tfvars file outside Git."
  type        = string
  sensitive   = true
}

variable "postgres_backup_retain_period_days" {
  description = "Automatic PostgreSQL backup retention in days."
  type        = number
  default     = 14
}
