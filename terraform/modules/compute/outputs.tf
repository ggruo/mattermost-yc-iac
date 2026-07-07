output "instance_id" {
  value = yandex_compute_instance.mattermost.id
}

output "public_ip_address" {
  value = yandex_compute_instance.mattermost.network_interface[0].nat_ip_address
}

output "private_ip_address" {
  value = yandex_compute_instance.mattermost.network_interface[0].ip_address
}
