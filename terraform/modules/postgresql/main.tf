# One private host: economical learning environment, not production HA.
resource "yandex_mdb_postgresql_cluster" "db" {
  name                = "${var.name}-db"
  environment         = "PRESTABLE"
  network_id          = var.network_id
  security_group_ids  = [var.security_group_id]
  deletion_protection = false
  config {
    version = "17"
    resources {
      resource_preset_id = var.preset
      disk_type_id       = "network-ssd"
      disk_size          = 20
    }
    backup_retain_period_days = 7
    backup_window_start {
      hours   = 2
      minutes = 0
    }
  }
  host {
    zone             = var.zone
    subnet_id        = var.subnet_id
    assign_public_ip = false
  }
}
resource "yandex_mdb_postgresql_user" "app" {
  cluster_id = yandex_mdb_postgresql_cluster.db.id
  name       = "notes"
  password   = var.password
}
resource "yandex_mdb_postgresql_database" "app" {
  cluster_id = yandex_mdb_postgresql_cluster.db.id
  name       = "notes"
  owner      = yandex_mdb_postgresql_user.app.name
}
output "host" {
  value = "c-${yandex_mdb_postgresql_cluster.db.id}.rw.mdb.yandexcloud.net"
}
output "cluster_id" {
  value = yandex_mdb_postgresql_cluster.db.id
}
