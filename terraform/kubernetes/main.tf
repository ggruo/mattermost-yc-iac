resource "yandex_kubernetes_cluster" "lab" {
  name                    = "notes-k8s"
  network_id              = yandex_vpc_network.lab.id
  cluster_ipv4_range      = "10.96.0.0/16"
  service_ipv4_range      = "10.112.0.0/16"
  service_account_id      = yandex_iam_service_account.cluster.id
  node_service_account_id = yandex_iam_service_account.node.id
  release_channel         = "STABLE"
  master {
    version   = var.kubernetes_version
    public_ip = true
    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.lab.id
    }
    security_group_ids = [yandex_vpc_security_group.app.id]
  }
  depends_on = [yandex_resourcemanager_folder_iam_member.cluster, yandex_resourcemanager_folder_iam_member.node]
}
resource "yandex_kubernetes_node_group" "lab" {
  cluster_id = yandex_kubernetes_cluster.lab.id
  name       = "notes-worker"
  version    = var.kubernetes_version
  instance_template {
    platform_id = "standard-v3"
    resources {
      cores  = var.node_cores
      memory = var.node_memory
    }
    boot_disk {
      type = "network-ssd"
      size = 30
    }
    network_interface {
      subnet_ids         = [yandex_vpc_subnet.lab.id]
      nat                = false
      security_group_ids = [yandex_vpc_security_group.app.id]
    }
    container_runtime { type = "containerd" }
  }
  scale_policy {
    fixed_scale { size = 1 }
  }
  allocation_policy {
    location { zone = var.zone }
  }
  maintenance_policy {
    auto_upgrade = false
    auto_repair  = true
  }
}
output "cluster_id" { value = yandex_kubernetes_cluster.lab.id }
