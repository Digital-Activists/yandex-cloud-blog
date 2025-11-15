# Тестовая сеть
resource "yandex_vpc_network" "network-1" {
  name = "blogicum"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "blogicum-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}
