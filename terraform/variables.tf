variable "cloud_id" {
  description = "Cloud ID"
  type        = string
}
variable "folder_id" {
  description = "Folder ID"
  type        = string
}
variable "zone" {
  description = "Zone"
  type        = string
  default     = "ru-central1-a"
}
variable "container_registry_id" {
  type = string
}
variable "docker_image_name" {
  description = "Name of the image with the application"
  type        = string
  default     = "app"
}
