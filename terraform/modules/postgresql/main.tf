resource "yandex_mdb_postgresql_cluster" "this" {
  name                = "${var.name_prefix}-postgres"
  environment         = "PRODUCTION"
  network_id          = var.network_id
  security_group_ids  = var.security_group_ids
  deletion_protection = true

  config {
    version = var.postgres_version

    resources {
      resource_preset_id = var.resource_preset_id
      disk_type_id       = var.disk_type_id
      disk_size          = var.disk_size
    }

    backup_window_start {
      hours   = 2
      minutes = 0
    }

    backup_retain_period_days = var.backup_retain_period_days
  }

  dynamic "host" {
    for_each = toset(var.zones)

    content {
      zone      = host.value
      subnet_id = var.subnet_ids[index(var.zones, host.value)]
    }
  }
}

resource "yandex_mdb_postgresql_user" "mattermost" {
  cluster_id = yandex_mdb_postgresql_cluster.this.id
  name       = var.db_user
  password   = var.db_password
  conn_limit = 50
}

resource "yandex_mdb_postgresql_database" "mattermost" {
  cluster_id = yandex_mdb_postgresql_cluster.this.id
  name       = var.db_name
  owner      = yandex_mdb_postgresql_user.mattermost.name
}
