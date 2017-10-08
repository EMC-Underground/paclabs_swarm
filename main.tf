provider "vsphere" {
  user           = "${var.vsphere_username}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_vcenter}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

resource "vsphere_virtual_machine" "swarm_manager" {
  name   = "swarm-master"
  domain = "${var.domain}"
  datacenter = "Datacenter"
  dns_servers = ["${var.dns}"]
  cluster = "cluster"
  vcpu   = 2
  memory = 4096

  network_interface {
    label = "${var.port_group}"
  }

  disk {
    template = "UbuntuTmpl"
    type = "thin"
    datastore = "${var.vsphere_datastore}"
  }

  provisioner "file" {
    source = "install-docker.sh"
    destination = "/tmp/install-docker.sh"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }

  provisioner "file" {
    source = "keys"
    destination = "/tmp/keys"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install-docker.sh",
      "sudo /tmp/install-docker.sh",
      "sudo docker swarm init --advertise-addr ${vsphere_virtual_machine.swarm_manager.network_interface.0.ipv4_address}"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }
}

data "external" "swarm_join_token" {
  program = ["./get-join-tokens.sh"]
  query = {
    host = "${vsphere_virtual_machine.swarm_manager.network_interface.0.ipv4_address}"
  }
}

resource "vsphere_virtual_machine" "swarm_worker" {
  count = "${var.swarm_worker_count}"
  name   = "swarm-worker-${count.index}"
  domain = "${var.domain}"
  datacenter = "Datacenter"
  dns_servers = ["${var.dns}"]
  cluster = "cluster"
  vcpu   = 2
  memory = 2048

  network_interface {
    label = "${var.port_group}"
  }

  disk {
    template = "UbuntuTmpl"
    type = "thin"
    datastore = "${var.vsphere_datastore}"
  }

  provisioner "file" {
    source = "install-docker.sh"
    destination = "/tmp/install-docker.sh"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }

  provisioner "file" {
    source = "keys"
    destination = "/tmp/keys"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install-docker.sh",
      "sudo /tmp/install-docker.sh",
      "sudo docker swarm join --token ${data.external.swarm_join_token.result.worker} ${vsphere_virtual_machine.swarm_manager.network_interface.0.ipv4_address}:2377"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }

}
output "manager_public_ip" {
  value = "${vsphere_virtual_machine.swarm_manager.network_interface.0.ipv4_address}"
}