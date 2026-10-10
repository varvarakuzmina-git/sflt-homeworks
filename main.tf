# Создаем облачную сеть
resource "yandex_vpc_network" "app-network" {
  name = "app-network"
}

# Создаем подсеть
resource "yandex_vpc_subnet" "app-subnet" {
  name           = "app-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.app-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Создаем 2 идентичные виртуальные машины с помощью count
resource "yandex_compute_instance" "nginx-vm" {
  count = 2
  name  = "nginx-vm-${count.index + 1}"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }


  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit" # Ubuntu 22.04 LTS
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat       = true
  }

  metadata = {
    user-data = file("${path.module}/cloud-init.yaml")
  }
}

# Создаем целевую группу
resource "yandex_lb_target_group" "app-target-group" {
  name = "app-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.nginx-vm
    content {
      subnet_id = yandex_vpc_subnet.app-subnet.id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

# Создаем сетевой балансировщик нагрузки
resource "yandex_lb_network_load_balancer" "app-load-balancer" {
  name = "app-load-balancer"

  listener {
    name = "app-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app-target-group.id

    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

# Выводим внешний IP-адрес балансировщика в терминал
output "load_balancer_ip" {
  value = [
    for listener in yandex_lb_network_load_balancer.app-load-balancer.listener : [
      for spec in listener.external_address_spec : spec.address
    ][0]
  ][0]
}