resource "yandex_container_registry" "django_repo" {
  name = "django-app"
}
output "registry_id" {
  value = yandex_container_registry.django_repo.id
}