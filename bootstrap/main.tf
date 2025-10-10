
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = "./key.json"
  cloud_id  = "b1ggid9nl12161umo6r8"
  folder_id = "b1grekf05a830gqkk35s"
  zone      = "ru-central1-a"
}

# Создание сервисного аккаунта для Terraform
resource "yandex_iam_service_account" "terraform_sa" {
  name        = "terraform-sa"
  description = "Сервисный аккаунт для управления инфраструктурой через Terraform"
}

# Назначение роли editor для управления ресурсами
resource "yandex_resourcemanager_folder_iam_member" "terraform_editor" {
  folder_id = "b1grekf05a830gqkk35s"
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_sa.id}"
}

# Назначение роли для управления storage
resource "yandex_resourcemanager_folder_iam_member" "terraform_storage_admin" {
  folder_id = "b1grekf05a830gqkk35s"
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_sa.id}"
}

# Создание статического ключа доступа для S3
resource "yandex_iam_service_account_static_access_key" "terraform_sa_static_key" {
  service_account_id = yandex_iam_service_account.terraform_sa.id
  description        = "Статический ключ для доступа к S3 bucket"
}

# Создание S3 bucket для хранения Terraform state
resource "yandex_storage_bucket" "terraform_state" {
  bucket     = "terraform-state-${yandex_iam_service_account.terraform_sa.id}"
  access_key = yandex_iam_service_account_static_access_key.terraform_sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform_sa_static_key.secret_key

  # Включаем версионирование для безопасности
  versioning {
    enabled = true
  }

  # Настройка жизненного цикла объектов
  lifecycle_rule {
    enabled = true
    
    # Удаляем старые версии через 90 дней
    noncurrent_version_expiration {
      days = 90
    }
  }
}

# Outputs для использования в основной конфигурации
output "service_account_id" {
  value       = yandex_iam_service_account.terraform_sa.id
  description = "ID сервисного аккаунта Terraform"
}

output "access_key" {
  value       = yandex_iam_service_account_static_access_key.terraform_sa_static_key.access_key
  description = "Access key для S3"
  sensitive   = true
}

output "secret_key" {
  value       = yandex_iam_service_account_static_access_key.terraform_sa_static_key.secret_key
  description = "Secret key для S3"
  sensitive   = true
}

output "bucket_name" {
  value       = yandex_storage_bucket.terraform_state.bucket
  description = "Имя S3 bucket для хранения state"
}

output "bucket_endpoint" {
  value       = "https://storage.yandexcloud.net"
  description = "Endpoint для подключения к S3"
}
