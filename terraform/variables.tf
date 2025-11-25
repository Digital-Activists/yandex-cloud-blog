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

variable "docker_image_name" {
  description = "Name of the image with the application"
  type        = string
  default     = "app"
}
variable "vm_image_id" {
  type        = string
  description = "ID образа ubuntu для виртуальной машины"
}
