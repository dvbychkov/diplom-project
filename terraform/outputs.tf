# Информация о сети
output "network_id" {
  value       = yandex_vpc_network.main.id
  description = "ID основной VPC сети"
}

# Публичные подсети
output "public_subnet_a_id" {
  value       = yandex_vpc_subnet.public_a.id
  description = "ID публичной подсети в зоне A"
}

output "public_subnet_b_id" {
  value       = yandex_vpc_subnet.public_b.id
  description = "ID публичной подсети в зоне B"
}

output "public_subnet_d_id" {
  value       = yandex_vpc_subnet.public_d.id
  description = "ID публичной подсети в зоне D"
}

# Приватные подсети
output "private_subnet_a_id" {
  value       = yandex_vpc_subnet.private_a.id
  description = "ID приватной подсети в зоне A"
}

output "private_subnet_b_id" {
  value       = yandex_vpc_subnet.private_b.id
  description = "ID приватной подсети в зоне B"
}

output "private_subnet_d_id" {
  value       = yandex_vpc_subnet.private_d.id
  description = "ID приватной подсети в зоне D"
}

# NAT instance
output "nat_instance_external_ip" {
  value       = yandex_compute_instance.nat_instance.network_interface.0.nat_ip_address
  description = "Внешний IP адрес NAT инстанса"
}

output "nat_instance_internal_ip" {
  value       = yandex_compute_instance.nat_instance.network_interface.0.ip_address
  description = "Внутренний IP адрес NAT инстанса"
}

# Security group
output "k8s_security_group_id" {
  value       = yandex_vpc_security_group.k8s_main_sg.id
  description = "ID группы безопасности для Kubernetes"
}

# Зоны доступности
output "zones" {
  value = {
    zone_a = "ru-central1-a"
    zone_b = "ru-central1-b"
    zone_d = "ru-central1-d"
  }
  description = "Используемые зоны доступности"
}
