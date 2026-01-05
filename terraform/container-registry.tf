resource "yandex_container_registry" "registry" {
  name = var.project_name
}
output "registry_id" {
  value = yandex_container_registry.registry.id
}
