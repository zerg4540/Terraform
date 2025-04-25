terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "y0__xCCzJGhARjB3RMg-pfc7BIwh9ak2QcIN77xtDdXsWmM-IOjLnmG4XF3Fw"
  cloud_id  = "b1g04rcjkqi795mqan9i"
  folder_id = "b1g2juipn7k7806uoicu"
  zone      = "ru-central1-a"
}

variable "virtual_machines" {
  description = "Configuration for virtual machines"
  type = map(object({
    vm_name   = string
    vm_desc   = string
    vm_cpu    = number
    ram       = number
    disk      = number
    disk_name = string
    template  = string
  }))
}

resource "yandex_compute_disk" "boot-disk" {
  for_each = var.virtual_machines
  name     = each.value.disk_name
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = each.value.disk
  image_id = each.value.template
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "virtual_machine" {
  for_each = var.virtual_machines
  name     = each.value.vm_name

  resources {
    cores  = each.value.vm_cpu
    memory = each.value.ram
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk[each.key].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "admin:${file("keytest.pub")}"
  }
}

output "vm_public_ips" {
  description = "Public IP addresses of the created VMs"
  value = {
    for key, vm in yandex_compute_instance.virtual_machine :
    key => vm.network_interface[0].nat_ip_address
  }
}
