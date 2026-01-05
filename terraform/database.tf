resource "yandex_iam_service_account" "db" {
  name = "${var.project_name}-db"
}

resource "yandex_resourcemanager_folder_iam_member" "db_cr_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.db.id}"
}

resource "yandex_compute_instance" "db" {
  name        = "${var.project_name}-db"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_latest.id
      size     = 20
    }
  }

  service_account_id = yandex_iam_service_account.db.id

  metadata = {
    ssh-keys  = "ubuntu:${file(var.ssh_key_pub_path)}"
    user-data = <<-EOF
#cloud-config
package_update: true
packages:
    - docker.io

runcmd:
    - systemctl start docker
    - systemctl enable docker

    # Аутентификация в registry от имени сервисного аккаунта
    - curl --header Metadata-Flavor:Google 169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token | cut -f1 -d',' | cut -f2 -d':' | tr -d '"' | docker login --username iam --password-stdin cr.yandex

    # Создание директории для данных PostgreSQL
    - mkdir -p /var/lib/postgres-data

    # Запуск PostgreSQL в фоне
    - |
        docker run -d \
        --name ${var.project_name}-postgres \
        --restart=always \
        -e POSTGRES_DB=${var.db_name} \
        -e POSTGRES_USER=${var.db_user} \
        -e POSTGRES_PASSWORD=${var.db_password} \
        -v /var/lib/postgres-data:/var/lib/postgresql/data \
        -p 5432:5432 \
        postgres:16
    EOF
  }
}
