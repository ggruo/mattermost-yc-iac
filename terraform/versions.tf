terraform {
  required_version = ">= 1.6.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.114.0"
    }
  }
}

provider "yandex" {
  zone = var.zone
}
