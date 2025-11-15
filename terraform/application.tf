resource "yandex_compute_instance" "app_vm" {
  name        = "blogicum-vm"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8clal01mnr2lnop5vr" # Ubuntu 24.04
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  # Предполагается, что уже существует registry и в нем находится образ с приложением
  metadata = {
    user-data = <<-EOF
      #cloud-config
      package_update: true
      packages:
        - docker.io
      runcmd:
        - systemctl start docker
        # TODO: Указать:
        # -e DJANGO_SECRET_KEY= \
        # -e DJANGO_STATIC_HOST= \
        # -e DATABASE_URL= \
        - docker run -d \
            --name ${var.docker_image_name} \
            -e DJANGO_DEBUG=False \
            -p 8000:8000 \
            cr.yandex/${var.container_registry_id}/${var.docker_image_name}:latest
    EOF
  }
}

output "django_vm_ip" {
  value = yandex_compute_instance.app_vm.network_interface.0.nat_ip_address
}
