
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  # Backend для хранения state в S3
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "terraform-state-ajernuoljgj9gjgvhn28"
    region = "ru-central1"
    key    = "terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true

  }
}

provider "yandex" {
  service_account_key_file = "./key.json"
  cloud_id                 = "b1ggid9nl12161umo6r8"
  folder_id                = "b1grekf05a830gqkk35s"
  zone                     = "ru-central1-a"
}

# Создание VPC сети
resource "yandex_vpc_network" "main" {
  name        = "k8s-network"
  description = "Сеть для Kubernetes кластера"
}

# Публичная подсеть в зоне A
resource "yandex_vpc_subnet" "public_a" {
  name           = "public-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
  description    = "Публичная подсеть в зоне ru-central1-a"
}

# Публичная подсеть в зоне B
resource "yandex_vpc_subnet" "public_b" {
  name           = "public-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.11.0/24"]
  description    = "Публичная подсеть в зоне ru-central1-b"
}

# Публичная подсеть в зоне D (для отказоустойчивости)
resource "yandex_vpc_subnet" "public_d" {
  name           = "public-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.12.0/24"]
  description    = "Публичная подсеть в зоне ru-central1-d"
}

# Приватная подсеть в зоне A
resource "yandex_vpc_subnet" "private_a" {
  name           = "private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private.id
  description    = "Приватная подсеть в зоне ru-central1-a"
}

# Приватная подсеть в зоне B
resource "yandex_vpc_subnet" "private_b" {
  name           = "private-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.21.0/24"]
  route_table_id = yandex_vpc_route_table.private.id
  description    = "Приватная подсеть в зоне ru-central1-b"
}

# Приватная подсеть в зоне D
resource "yandex_vpc_subnet" "private_d" {
  name           = "private-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.22.0/24"]
  route_table_id = yandex_vpc_route_table.private.id
  description    = "Приватная подсеть в зоне ru-central1-d"
}

# NAT-инстанс для доступа приватных подсетей в интернет
# Используем прерываемую ВМ для экономии
resource "yandex_compute_instance" "nat_instance" {
  name        = "nat-instance"
  zone        = "ru-central1-a"
  hostname    = "nat-instance"
  description = "NAT инстанс для маршрутизации трафика из приватных подсетей"

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20 # Минимальная доля CPU для экономии
  }

  boot_disk {
    initialize_params {
      # Образ NAT-инстанса от Yandex Cloud
      image_id = "fd80mrhj8fl2oe87o4e1"
      size     = 10
      type     = "network-hdd" # Самый дешевый тип диска
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public_a.id
    nat        = true
    ip_address = "192.168.10.254"
  }

  metadata = {
    user-data = file("./meta.txt")
  }
}

# Таблица маршрутизации для приватных подсетей
resource "yandex_vpc_route_table" "private" {
  name        = "private-route-table"
  network_id  = yandex_vpc_network.main.id
  description = "Маршрутизация трафика из приватных подсетей через NAT"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat_instance.network_interface.0.ip_address
  }
}

# Security group для Kubernetes
resource "yandex_vpc_security_group" "k8s_main_sg" {
  name        = "k8s-main-sg"
  description = "Группа безопасности для Kubernetes кластера"
  network_id  = yandex_vpc_network.main.id

  # Разрешаем входящий трафик внутри подсетей
  ingress {
    protocol       = "ANY"
    description    = "Весь трафик внутри подсетей"
    v4_cidr_blocks = ["192.168.0.0/16"]
  }

  # Разрешаем SSH
  ingress {
    protocol       = "TCP"
    description    = "SSH доступ"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Разрешаем HTTPS для Kubernetes API
  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  # Разрешаем HTTP/HTTPS для приложений
  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  # Разрешаем весь исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "Весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
