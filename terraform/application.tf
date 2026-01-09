# Сервисный аккаунт для группы ВМ
resource "yandex_iam_service_account" "app_group" {
  name = "${var.project_name}-instance-group"
}

# Для группы ВМ нужны роли: storage.editor, vpc.user, resource-manager.viewer, compute.editor
# Вместо экспериментов с поиском минимально необходимого набора ролей, назначаем сервисному аккаунту: editor.
resource "yandex_resourcemanager_folder_iam_member" "app_group_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.app_group.id}"
}



# Сервисный аккаунт для виртуальных машин в группе
resource "yandex_iam_service_account" "app_vm" {
  name = "${var.project_name}-app-vm"
}

# Право на pull образов из Container Registry
resource "yandex_resourcemanager_folder_iam_member" "app_vm_cr_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.app_vm.id}"

  depends_on = [yandex_iam_service_account.app_vm]
}

resource "yandex_resourcemanager_folder_iam_member" "app_vm_storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.app_vm.id}"

  depends_on = [yandex_iam_service_account.app_vm]
}

resource "yandex_resourcemanager_folder_iam_member" "app_vm_monitoring_editor" {
  folder_id = var.folder_id
  role      = "monitoring.editor"
  member    = "serviceAccount:${yandex_iam_service_account.app_vm.id}"
}


resource "yandex_compute_instance_group" "app_group" {
  name               = "${var.project_name}-group"
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.app_group.id

  depends_on = [
    yandex_compute_instance.db,
    yandex_resourcemanager_folder_iam_member.app_group_editor,
    yandex_resourcemanager_folder_iam_member.app_vm_cr_puller,
    yandex_resourcemanager_folder_iam_member.app_vm_storage_editor,
    # yandex_vpc_subnet.subnet-a,
    yandex_vpc_subnet.subnet-b
    # yandex_vpc_subnet.subnet-d,
  ]

  allocation_policy {
    zones = ["ru-central1-b"]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }

  scale_policy {
    auto_scale {
      // Количество инстансов должно быть >= количества указанных zones в allocation_policy
      initial_size           = 1
      measurement_duration   = 270
      cpu_utilization_target = 80
      max_size               = 3
    }
  }

  load_balancer {
    target_group_name = "${var.project_name}-target-group"
  }

  # health_check {
  #   tcp_options {
  #     port = 8000
  #   }
  #   interval            = 5
  #   unhealthy_threshold = 4
  # }

  instance_template {
    platform_id        = "standard-v3"
    service_account_id = yandex_iam_service_account.app_vm.id

    boot_disk {
      initialize_params {
        image_id = data.yandex_compute_image.ubuntu_latest.id
        size     = 10
      }
    }

    network_interface {
      network_id = yandex_vpc_network.network-1.id
      subnet_ids = [
        # yandex_vpc_subnet.subnet-a.id,
        yandex_vpc_subnet.subnet-b.id,
        # yandex_vpc_subnet.subnet-d.id
      ]
      nat = true // TODO: Нужно для отладки, убрать потом
    }

    resources {
      memory = 2
      cores  = 2
    }

    metadata = {
      ssh-keys  = "ubuntu:${file(var.ssh_key_pub_path)}"
      user-data = <<-EOF
#cloud-config
package_update: true
packages:
  - docker.io

write_files:
  - path: /etc/yc/unified_agent/${var.project_name}-config.yml
    permissions: '0644'
    content: |
      status:
        port: "16241"

      storages:
        - name: main
          plugin: fs
          config:
            directory: /var/lib/yandex/unified_agent/main
            max_partition_size: 100mb
            max_segment_size: 10mb

      channels:
        - name: cloud_monitoring
          channel:
            pipe:
              - storage_ref:
                  name: main
            output:
              plugin: yc_metrics
              config:
                folder_id: "${var.folder_id}"
                iam:
                  cloud_meta: {}

      routes:
        - input:
            plugin: metrics_pull
            config:
              url: http://127.0.0.1:8000/metrics
              metric_name_label: ${var.project_name}_name
              format:
                prometheus: {}
              namespace: app
          channel:
            channel_ref:
              name: cloud_monitoring

        - input:
            plugin: agent_metrics
            config:
              namespace: ua
          channel:
            pipe:
              - filter:
                  plugin: filter_metrics
                  config:
                    match: "{scope=health}"
            channel_ref:
              name: cloud_monitoring

runcmd:
  - systemctl start docker
  - systemctl enable docker

  # Аутентификация в registry от имени сервисного аккаунта
  - curl --header Metadata-Flavor:Google 169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token | cut -f1 -d',' | cut -f2 -d':' | tr -d '"' | docker login --username iam --password-stdin cr.yandex

  # Цикл ожидания доступности образа
  - |
      set +e
      while true; do
          docker pull ${var.app_image_url} > /dev/null 2>&1 && break
          sleep 20
      done
      set -e

  # Запуск Django-контейнера после успешного pull
  - | 
      docker run -d \
      --name ${var.project_name} \
      --restart=always \
      -e DJANGO_DEBUG=False \
      -e AWS_ACCESS_KEY_ID=${yandex_iam_service_account_static_access_key.storage-static-key.access_key} \
      -e AWS_SECRET_ACCESS_KEY=${yandex_iam_service_account_static_access_key.storage-static-key.secret_key} \
      -e AWS_STORAGE_BUCKET_NAME=${yandex_storage_bucket.bucket.bucket} \
      -e AWS_S3_ENDPOINT_URL="https://storage.yandexcloud.net" \
      -e DATABASE_URL="postgres://${var.db_user}:${var.db_password}@${yandex_compute_instance.db.network_interface.0.ip_address}:5432/${var.db_name}?sslmode=disable" \
      -p 8000:8000 \
      ${var.app_image_url}
  
  # Запуск Yandex Unified Agent
  - |
      docker run \
      -p 16241:16241 -it --detach --uts=host \
      --name=ua \
      --network=host \
      -v /proc:/ua_proc \
      -v /etc/yc/unified_agent/${var.project_name}-config.yml:/etc/yandex/unified_agent/conf.d/config.yml \
      -e PROC_DIRECTORY=/ua_proc \
      -e FOLDER_ID=${var.folder_id} \
      cr.yandex/yc/unified-agent
EOF
    }
  }
}
