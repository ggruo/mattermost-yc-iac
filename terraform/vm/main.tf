resource "yandex_vpc_network" "lab" {
  name = "notes-vm"
}
resource "yandex_vpc_subnet" "lab" {
  name           = "notes-vm-a"
  network_id     = yandex_vpc_network.lab.id
  zone           = var.zone
  v4_cidr_blocks = ["10.10.10.0/24"]
}
resource "yandex_vpc_security_group" "app" {
  name       = "notes-vm-app"
  network_id = yandex_vpc_network.lab.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.trusted_cidrs
  }
  dynamic "ingress" {
    for_each = [80, 443]
    content {
      protocol       = "TCP"
      port           = ingress.value
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}
resource "yandex_vpc_address" "app" {
  name = "notes-vm"
  external_ipv4_address { zone_id = var.zone }
}
resource "yandex_compute_instance" "app" {
  name        = "notes-vm"
  zone        = var.zone
  platform_id = "standard-v3"
  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
      type     = "network-ssd"
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.lab.id
    nat                = true
    nat_ip_address     = yandex_vpc_address.app.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.app.id]
  }
  metadata = {
    user-data = "#cloud-config\n${yamlencode({
      users          = [{ name = "ubuntu", groups = "sudo", shell = "/bin/bash", sudo = "ALL=(ALL) NOPASSWD:ALL", ssh_authorized_keys = [trimspace(file(pathexpand(var.ssh_public_key_path)))] }]
      package_update = true
      packages       = ["python3", "python3-apt"]
    })}"
  }
}
resource "yandex_dns_recordset" "app" {
  zone_id = var.dns_zone_id
  name    = "${var.fqdn}."
  type    = "A"
  ttl     = 60
  data    = [yandex_vpc_address.app.external_ipv4_address[0].address]
}
output "vm_public_ip" { value = yandex_vpc_address.app.external_ipv4_address[0].address }
output "fqdn" { value = var.fqdn }
