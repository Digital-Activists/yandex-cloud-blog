variable "token" {
  description = "Token полученный для сервисного аккаунта"
  type        = string
}
variable "ssh_key_pub_path" {
  type        = string
  description = "Path to the public part of SSH-key"
  default     = "~/.ssh/id_ed25519.pub"
}

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
  default     = "ru-central1-b"
}

variable "project_name" {
  type    = string
  default = "blogicum"
}
variable "app_image_url" {
  description = "URL to app image in from container registry"
  type        = string
}

variable "db_user" {
  type    = string
  default = "user"
}
variable "db_name" {
  type    = string
  default = "blogicum"
}
variable "db_password" {
  type    = string
  default = "password"
}
