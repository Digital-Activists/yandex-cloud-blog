# Container registry
resource "yandex_cr_repository" "django_repo" {
  name = "django-app"
}
