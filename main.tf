terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

variable "pm_root_password" {
  type = string
  sensitive = true
  description = "Proxmox root password"
}

variable "ct_password" {
  type = string
  sensitive = true
  description = "Root password for LXC container"
}

variable "ssh_public_keys" {
  type = string
  sensitive = true
  description = "Public keys to add to LXC container"
}

provider "proxmox" {
  pm_debug = true
  pm_user = "root@pam"
  pm_password = var.pm_root_password
  pm_api_url = "https://pve1.home.famroos.nu:8006/api2/json"
}

resource "proxmox_lxc" "k3s-sn" {
  target_node  = "pve1"
  hostname     = "k3s-sn"
  ostemplate   = "local:vztmpl/debian-11-standard_11.6-1_amd64.tar.zst"
  password     = var.ct_password
  unprivileged = true

  ssh_public_keys = var.ssh_public_keys

  start = true
  onboot = true

  vmid = 1020
  cores = 1
  memory = 2048

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local-lvm"
    size    = "5G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }

  // Enable features required to run Docker k3s-sn
  features {
    keyctl  = true
    fuse    = true
    nesting = true
  }

  provisioner "remote-exec" {
    when    = create
    connection {
      type     = "ssh"
      user     = "root"
      private_key = "${file("../../Doc/StriktPersoonlijk/SSH-keys/NAS-Admin/id_rsa")}"
      host     = "k3s-sn.home.famroos.nu"
    }

    inline = [
      "mkdir -p /run/sshd",
      "echo 'd /run/sshd 0755 root root' >> /usr/lib/tmpfiles.d/sshd.conf"
    ]
  }

  provisioner "local-exec" {
    working_dir = "ansible"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i k3s-sn.home.famroos.nu, --user root --private-key ../../secrets/id_rsa k3s-sn.yml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R k3s-sn.home.famroos.nu"
  }
}
