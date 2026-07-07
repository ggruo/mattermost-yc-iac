resource "yandex_vpc_security_group" "vm" {
  name       = "${var.name_prefix}-vm-sg"
  network_id = var.network_id

  ingress {
    description    = "HTTP for ACME challenge and redirect"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS public access"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "SSH from trusted networks"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.trusted_ssh_cidrs
  }

  egress {
    description    = "Outbound internet and private network access"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "postgres" {
  name       = "${var.name_prefix}-postgres-sg"
  network_id = var.network_id

  ingress {
    description       = "PostgreSQL from Mattermost VM"
    protocol          = "TCP"
    port              = 6432
    security_group_id = yandex_vpc_security_group.vm.id
  }

  ingress {
    description       = "PostgreSQL direct port from Mattermost VM"
    protocol          = "TCP"
    port              = 5432
    security_group_id = yandex_vpc_security_group.vm.id
  }

  egress {
    description    = "Managed service outbound traffic"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
