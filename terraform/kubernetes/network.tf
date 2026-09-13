resource "yandex_vpc_network" "lab" {
  name = "notes-k8s"
}
resource "yandex_vpc_gateway" "nat" {
  name = "notes-egress"
  shared_egress_gateway {}
}
resource "yandex_vpc_route_table" "egress" {
  network_id = yandex_vpc_network.lab.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}
resource "yandex_vpc_subnet" "lab" {
  name           = "notes-k8s-a"
  network_id     = yandex_vpc_network.lab.id
  zone           = var.zone
  v4_cidr_blocks = ["10.20.10.0/24"]
  route_table_id = yandex_vpc_route_table.egress.id
}
# Shared control-plane/node group: self traffic and Pod/Service CIDRs.
resource "yandex_vpc_security_group" "app" {
  name       = "notes-k8s-app"
  network_id = yandex_vpc_network.lab.id
  ingress {
    description       = "Control plane and nodes"
    protocol          = "ANY"
    predefined_target = "self_security_group"
  }
  ingress {
    description    = "Pod and Service routing"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.96.0.0/16", "10.112.0.0/16"]
  }
  ingress {
    description       = "Cloud load balancer health checks"
    protocol          = "TCP"
    from_port         = 0
    to_port           = 65535
    predefined_target = "loadbalancer_healthchecks"
  }
  dynamic "ingress" {
    for_each = [443, 6443]
    content {
      description    = "Administrator API access"
      protocol       = "TCP"
      port           = ingress.value
      v4_cidr_blocks = var.trusted_cidrs
    }
  }
  ingress {
    description       = "ALB backend NodePort"
    protocol          = "TCP"
    port              = 30080
    security_group_id = yandex_vpc_security_group.alb.id
  }
  ingress {
    description       = "ALB controller backend health checks"
    protocol          = "TCP"
    port              = 30501
    security_group_id = yandex_vpc_security_group.alb.id
  }
  dynamic "ingress" {
    for_each = var.enable_nlb ? [1] : []
    content {
      description    = "NLB preserves client IP; nodes have no public IP"
      protocol       = "TCP"
      port           = 30081
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "yandex_vpc_security_group" "alb" {
  name       = "notes-alb"
  network_id = yandex_vpc_network.lab.id
  dynamic "ingress" {
    for_each = [80, 443]
    content {
      protocol       = "TCP"
      port           = ingress.value
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }
  ingress {
    protocol          = "TCP"
    port              = 30080
    predefined_target = "loadbalancer_healthchecks"
  }
  egress {
    description    = "Backends in the node subnet (avoids cyclic SG references)"
    protocol       = "TCP"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["10.20.10.0/24"]
  }
}
output "subnet_id" { value = yandex_vpc_subnet.lab.id }
output "alb_security_group_id" { value = yandex_vpc_security_group.alb.id }
