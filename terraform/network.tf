# Тестовая сеть
resource "yandex_vpc_network" "network-1" {
  name      = "${var.project_name}-net"
  folder_id = var.folder_id
}

resource "yandex_vpc_subnet" "subnet-a" {
  name           = "${var.project_name}-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.2.0.0/16"]
  folder_id      = var.folder_id
}

resource "yandex_vpc_subnet" "subnet-d" {
  name           = "${var.project_name}-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.3.0.0/16"]
  folder_id      = var.folder_id
}

resource "yandex_vpc_subnet" "subnet-b" {
  name           = "${var.project_name}-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.4.0.0/16"]
  folder_id      = var.folder_id
}
