// Create SA
resource "yandex_iam_service_account" "storage-sa" {
  folder_id = var.folder_id
  name      = "${var.project_name}-storage"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "storage-sa-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage-sa.id}"
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "storage-static-key" {
  service_account_id = yandex_iam_service_account.storage-sa.id
  description        = "static access key for object storage"
}

// Use keys to create bucket
resource "yandex_storage_bucket" "bucket" {
  access_key = yandex_iam_service_account_static_access_key.storage-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage-static-key.secret_key
  bucket     = "${var.project_name}-bucket-rit90v58v8n759m9"
}
