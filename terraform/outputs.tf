output "mattermost_fqdn" {
  description = "Mattermost public FQDN."
  value       = var.mattermost_fqdn
}

output "mattermost_url" {
  description = "Mattermost public HTTPS URL."
  value       = "https://${var.mattermost_fqdn}"
}

output "vm_public_ip" {
  description = "Public IP address of the Mattermost VM."
  value       = module.compute.public_ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the Mattermost VM."
  value       = module.compute.private_ip_address
}

output "ssh_username" {
  description = "SSH username for Ansible."
  value       = var.ssh_username
}

output "postgres_hosts" {
  description = "Managed PostgreSQL host FQDNs."
  value       = module.postgresql.host_fqdns
}

output "postgres_primary_host" {
  description = "First Managed PostgreSQL host FQDN for initial client configuration."
  value       = module.postgresql.primary_host_fqdn
}

output "postgres_db_name" {
  description = "Mattermost PostgreSQL database name."
  value       = var.postgres_db_name
}

output "postgres_user" {
  description = "Mattermost PostgreSQL username."
  value       = var.postgres_user
}
