locals {
  name_prefix    = "${var.project_name}-${var.environment}"
  ssh_public_key = trimspace(file(var.ssh_public_key_path))
}

module "network" {
  source = "./modules/network"

  name_prefix     = local.name_prefix
  zones           = var.zones
  subnet_cidrs    = var.subnet_cidrs
  domain_name     = var.domain_name
  mattermost_fqdn = var.mattermost_fqdn
  create_dns_zone = var.create_dns_zone
  dns_zone_id     = var.dns_zone_id
}

module "security" {
  source = "./modules/security"

  name_prefix       = local.name_prefix
  network_id        = module.network.network_id
  trusted_ssh_cidrs = var.trusted_ssh_cidrs
}

module "postgresql" {
  source = "./modules/postgresql"

  name_prefix               = local.name_prefix
  network_id                = module.network.network_id
  subnet_ids                = module.network.subnet_ids
  zones                     = var.zones
  security_group_ids        = [module.security.postgres_security_group_id]
  postgres_version          = var.postgres_version
  resource_preset_id        = var.postgres_resource_preset_id
  disk_type_id              = var.postgres_disk_type_id
  disk_size                 = var.postgres_disk_size
  db_name                   = var.postgres_db_name
  db_user                   = var.postgres_user
  db_password               = var.postgres_password
  backup_retain_period_days = var.postgres_backup_retain_period_days
}

module "compute" {
  source = "./modules/compute"

  name_prefix        = local.name_prefix
  zone               = var.zones[0]
  subnet_id          = module.network.subnet_ids[0]
  security_group_ids = [module.security.vm_security_group_id]
  ssh_username       = var.ssh_username
  ssh_public_key     = local.ssh_public_key
  platform_id        = var.vm_platform_id
  cores              = var.vm_cores
  memory             = var.vm_memory
  core_fraction      = var.vm_core_fraction
  boot_disk_size     = var.vm_boot_disk_size
  image_family       = var.vm_image_family
}

resource "yandex_dns_recordset" "mattermost" {
  zone_id = module.network.dns_zone_id
  name    = "${var.mattermost_fqdn}."
  type    = "A"
  ttl     = 300
  data    = [module.compute.public_ip_address]
}
