output "cluster_id" {
  value = yandex_mdb_postgresql_cluster.this.id
}

output "host_fqdns" {
  value = [for host in yandex_mdb_postgresql_cluster.this.host : host.fqdn]
}

output "primary_host_fqdn" {
  value = yandex_mdb_postgresql_cluster.this.host[0].fqdn
}
