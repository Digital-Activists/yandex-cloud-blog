# Сервисный аккаунт для виртуальной машины
resource "yandex_iam_service_account" "app_sa" {
  name = "application-sa"
}
# Право на запись в Cloud Logs
# resource "yandex_resourcemanager_folder_iam_member" "fluent_bit_logs_writer" {
#   folder_id = var.folder_id
#   role      = "logging.writer"
#   member    = "serviceAccount:${yandex_iam_service_account.app_sa.id}"
# }
# Право на pull образов из Container Registry
resource "yandex_resourcemanager_folder_iam_member" "cr_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.app_sa.id}"
}

# resource "yandex_logging_group" "django_logs" {
#   name      = "django-app-logs"
#   folder_id = var.folder_id
# }

resource "yandex_compute_instance" "app_vm" {
  name        = "application-vm"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  service_account_id = yandex_iam_service_account.app_sa.id

  metadata = {
    ssh-keys  = "user:${file("~/.ssh/id_ed25519.pub")}"
    user-data = <<-EOF
#cloud-config
package_update: true
packages:
    - docker.io

runcmd:
    # Запуск Docker
    - systemctl start docker
    - systemctl enable docker

    # Аутентификация в registry от имени сервисного аккаунта
    - curl --header Metadata-Flavor:Google 169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token | cut -f1 -d',' | cut -f2 -d':' | tr -d '"' | docker login --username iam --password-stdin cr.yandex

    # Цикл ожидания доступности образа
    - |
        set +e
        while true; do
            docker pull cr.yandex/${yandex_container_registry.django_repo.id}/${var.docker_image_name}:latest > /dev/null 2>&1 && break
            sleep 20
        done
        set -e

    # Запуск Django-контейнера после успешного pull
    - docker run -d --name app -e DJANGO_DEBUG=False -p 8000:8000 cr.yandex/${yandex_container_registry.django_repo.id}/${var.docker_image_name}:latest
    EOF
  }
}

output "django_vm_ip" {
  value = yandex_compute_instance.app_vm.network_interface.0.nat_ip_address
}
