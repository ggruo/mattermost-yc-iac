data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

resource "yandex_vpc_address" "public" {
  name = "${var.name_prefix}-public-ip"

  external_ipv4_address {
    zone_id = var.zone
  }
}

resource "yandex_compute_instance" "mattermost" {
  name        = "${var.name_prefix}-vm"
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.boot_disk_size
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = true
    nat_ip_address     = yandex_vpc_address.public.external_ipv4_address[0].address
    security_group_ids = var.security_group_ids
  }

  metadata = {
    user-data = templatefile("${path.root}/cloud-init.yml.tftpl", {
      ssh_username   = var.ssh_username
      ssh_public_key = var.ssh_public_key
    })
  }
}
