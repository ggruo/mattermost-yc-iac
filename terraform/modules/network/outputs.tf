output "network_id" {
  value = yandex_vpc_network.this.id
}

output "subnet_ids" {
  value = yandex_vpc_subnet.app[*].id
}

output "dns_zone_id" {
  value = var.create_dns_zone ? yandex_dns_zone.this[0].id : var.dns_zone_id
}
