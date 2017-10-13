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
    source = "files/"
    destination = "/tmp"

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
      "sudo docker swarm init --advertise-addr ${vsphere_virtual_machine.swarm_manager.network_interface.0.ipv4_address}",
      "echo 'y' | sudo docker plugin install rexray/scaleio SCALEIO_ENDPOINT=https://192.168.0.120/api SCALEIO_USERNAME=admin SCALEIO_PASSWORD=Password#1 SCALEIO_SYSTEMID=0 SCALEIO_PROTECTIONDOMAINNAME=default SCALEIO_STORAGEPOOLNAME=default REXRAY_LOGLEVEL=debug"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }
}

resource "vsphere_virtual_machine" "swarm_worker" {
  depends_on = ["vsphere_virtual_machine.swarm_manager"]
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
    source = "files/"
    destination = "/tmp"

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
      "`docker -H=swarm-master:2375 swarm join-token worker | awk '{if(NR>1)print}'`",
      "echo 'y' | sudo docker plugin install rexray/scaleio SCALEIO_ENDPOINT=https://192.168.0.120/api SCALEIO_USERNAME=admin SCALEIO_PASSWORD=Password#1 SCALEIO_SYSTEMID=0 SCALEIO_PROTECTIONDOMAINNAME=default SCALEIO_STORAGEPOOLNAME=default REXRAY_LOGLEVEL=debug"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }

  provisioner "remote-exec" {
    when = "destroy"
    on_failure = "continue"
    inline = [
      "docker swarm leave",
      "sleep 15",
      "docker -H=swarm-master:2375 node rm `docker -H=swarm-master:2375 node ls | grep Down | awk '{print $1;}'`"
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
