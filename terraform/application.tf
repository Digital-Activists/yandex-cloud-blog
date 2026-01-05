# Сервисный аккаунт для виртуальной машины
resource "yandex_iam_service_account" "app" {
  name = "${var.project_name}-application-sa"
}

# Право на pull образов из Container Registry
resource "yandex_resourcemanager_folder_iam_member" "app_cr_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.app.id}"
}

# Тестовая VM
resource "yandex_compute_instance" "app_vm" {
  name        = "${var.project_name}-application"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_latest.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  service_account_id = yandex_iam_service_account.app.id

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

    # Цикл ожидания доступности образа
    - |
        set +e
        while true; do
            docker pull cr.yandex/${yandex_container_registry.registry.id}/${var.docker_image_name}:latest > /dev/null 2>&1 && break
            sleep 20
        done
        set -e

    # Запуск Django-контейнера после успешного pull
    - | docker run -d
        --name ${var.project_name}
        -e DJANGO_DEBUG=False
        -e AWS_ACCESS_KEY_ID=${yandex_iam_service_account_static_access_key.storage-static-key.access_key}
        -e AWS_SECRET_ACCESS_KEY=${yandex_iam_service_account_static_access_key.storage-static-key.secret_key}
        -e AWS_STORAGE_BUCKET_NAME=${yandex_storage_bucket.bucket.bucket}
        -e AWS_S3_ENDPOINT_URL="https://storage.yandexcloud.net"
        -e "postgres://${var.db_user}:${var.db_password}@${yandex_compute_instance.db.network_interface.0.nat_ip_address}:5432/${var.db_name}?sslmode=disable"
        -p 8000:8000
        cr.yandex/${yandex_container_registry.registry.id}/${var.docker_image_name}:latest
    EOF
  }
}
