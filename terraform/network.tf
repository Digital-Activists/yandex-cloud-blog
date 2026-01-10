/////// Networks ///////

resource "yandex_vpc_network" "net" {
  name      = "${var.project_name}-db"
  folder_id = var.folder_id
}

/////// Subnets ///////

resource "yandex_vpc_subnet" "app" {
  name           = "${var.project_name}-app"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.1.0.0/16"]
  folder_id      = var.folder_id
}

resource "yandex_vpc_subnet" "db" {
  name           = "${var.project_name}-db"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.2.0.0/16"]
  folder_id      = var.folder_id
}

/////// Security Groups ///////

resource "yandex_vpc_security_group" "db" {
  name       = "postgres"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "app" {
  name       = "${var.project_name}-app"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 22
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 8000
    description    = "${var.project_name}-application"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
