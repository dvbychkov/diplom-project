
# Получаем актуальный образ Ubuntu 20.04 LTS
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

# Master node (Control Plane)
resource "yandex_compute_instance" "k8s_master" {
  name        = "k8s-master"
  hostname    = "k8s-master"
  zone        = "ru-central1-a"
  description = "Kubernetes Master Node"

  # Прерываемая ВМ для экономии
  scheduling_policy {
    preemptible = true
  }

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_main_sg.id]
  }

  metadata = {
    user-data = file("./meta.txt")
  }

  # Разрешаем удаление с диском
  allow_stopping_for_update = true
}

# Worker node 1 в зоне A
resource "yandex_compute_instance" "k8s_worker_1" {
  name        = "k8s-worker-1"
  hostname    = "k8s-worker-1"
  zone        = "ru-central1-a"
  description = "Kubernetes Worker Node 1"

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_main_sg.id]
  }

  metadata = {
    user-data = file("./meta.txt")
  }

  allow_stopping_for_update = true
}

# Worker node 2 в зоне B (для распределения нагрузки)
resource "yandex_compute_instance" "k8s_worker_2" {
  name        = "k8s-worker-2"
  hostname    = "k8s-worker-2"
  zone        = "ru-central1-b"
  description = "Kubernetes Worker Node 2"

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_b.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_main_sg.id]
  }

  metadata = {
    user-data = file("./meta.txt")
  }

  allow_stopping_for_update = true
}

# Outputs для Kubernetes нод
output "k8s_master_external_ip" {
  value       = yandex_compute_instance.k8s_master.network_interface.0.nat_ip_address
  description = "Внешний IP адрес Kubernetes Master"
}

output "k8s_master_internal_ip" {
  value       = yandex_compute_instance.k8s_master.network_interface.0.ip_address
  description = "Внутренний IP адрес Kubernetes Master"
}

output "k8s_worker_1_external_ip" {
  value       = yandex_compute_instance.k8s_worker_1.network_interface.0.nat_ip_address
  description = "Внешний IP адрес Worker 1"
}

output "k8s_worker_1_internal_ip" {
  value       = yandex_compute_instance.k8s_worker_1.network_interface.0.ip_address
  description = "Внутренний IP адрес Worker 1"
}

output "k8s_worker_2_external_ip" {
  value       = yandex_compute_instance.k8s_worker_2.network_interface.0.nat_ip_address
  description = "Внешний IP адрес Worker 2"
}

output "k8s_worker_2_internal_ip" {
  value       = yandex_compute_instance.k8s_worker_2.network_interface.0.ip_address
  description = "Внутренний IP адрес Worker 2"
}
