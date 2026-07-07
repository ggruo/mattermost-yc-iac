output "vm_security_group_id" {
  value = yandex_vpc_security_group.vm.id
}

output "postgres_security_group_id" {
  value = yandex_vpc_security_group.postgres.id
}
