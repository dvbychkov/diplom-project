# ============================================
# Yandex Container Registry
# Для хранения Docker образов
# ============================================

# Получение существующего сервисного аккаунта
data "yandex_iam_service_account" "terraform_sa" {
  service_account_id = "ajernuoljgj9gjgvhn28" # ID из bootstrap
}

# Создание Container Registry
resource "yandex_container_registry" "app_registry" {
  name      = "diplom-registry"
  folder_id = "b1grekf05a830gqkk35s"

  labels = {
    project     = "diplom"
    environment = "production"
  }
}

# Назначение прав на pull образов (для всех, упрощённый вариант)
resource "yandex_container_registry_iam_binding" "puller" {
  registry_id = yandex_container_registry.app_registry.id
  role        = "container-registry.images.puller"

  members = [
    "system:allUsers", # Все пользователи могут скачивать образы
  ]
}

# Назначение прав на push образов для CI/CD
resource "yandex_container_registry_iam_binding" "pusher" {
  registry_id = yandex_container_registry.app_registry.id
  role        = "container-registry.images.pusher"

  members = [
    "serviceAccount:${data.yandex_iam_service_account.terraform_sa.id}",
  ]
}

# Output registry ID
output "container_registry_id" {
  value       = yandex_container_registry.app_registry.id
  description = "ID Container Registry"
}

output "container_registry_endpoint" {
  value       = "cr.yandex/${yandex_container_registry.app_registry.id}"
  description = "Endpoint для push/pull образов"
}
