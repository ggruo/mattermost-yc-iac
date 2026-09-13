resource "yandex_vpc_security_group" "db" {
  name       = "notes-kubernetes-db"
  network_id = yandex_vpc_network.lab.id
  ingress {
    description       = "Only application hosts may connect to PostgreSQL"
    protocol          = "TCP"
    port              = 6432
    security_group_id = yandex_vpc_security_group.app.id
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
module "postgresql" {
  source            = "../modules/postgresql"
  name              = "notes-kubernetes"
  zone              = var.zone
  network_id        = yandex_vpc_network.lab.id
  subnet_id         = yandex_vpc_subnet.lab.id
  security_group_id = yandex_vpc_security_group.db.id
  preset            = var.postgres_preset
  password          = var.postgres_password
}
output "postgres_host" {
  value = module.postgresql.host
}
output "postgres_cluster_id" {
  value = module.postgresql.cluster_id
}
