resource "yandex_lb_network_load_balancer" "app" {
  name      = "${var.project_name}-network-load-balancer"
  folder_id = var.folder_id

  depends_on = [yandex_compute_instance_group.app_group]

  listener {
    name = "${var.project_name}-listener"
    port = 8000
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.app_group.load_balancer[0].target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 8000
        path = "/"
      }
    }
  }
}
