resource "yandex_vpc_network" "this" {
  name = "${var.name_prefix}-network"
}

resource "yandex_vpc_subnet" "app" {
  count = length(var.zones)

  name           = "${var.name_prefix}-subnet-${var.zones[count.index]}"
  zone           = var.zones[count.index]
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.subnet_cidrs[count.index]]
}

resource "yandex_dns_zone" "this" {
  count = var.create_dns_zone ? 1 : 0

  name   = "${var.name_prefix}-dns-zone"
  zone   = "${var.domain_name}."
  public = true
}
