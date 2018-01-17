provider "vsphere" {
  user           = "${var.vsphere_username}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_vcenter}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

resource "vsphere_virtual_machine" "swarm_master" {
  name   = "swarm-master"
  domain = "${var.domain}"
  datacenter = "${var.vsphere_datacenter}"
  dns_servers = ["${var.dns}"]
  cluster = "${var.vsphere_cluster}"
  vcpu   = 2
  memory = 4096

  network_interface {
    label = "${var.vsphere_port_group_1}"
    ipv4_address = "${var.vsphere_public_ip}"
    ipv4_prefix_length = "24"
    ipv4_gateway = "${var.vsphere_gateway}"
  }

  network_interface {
    label = "${var.vsphere_port_group_2}"
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
      "sudo chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
      "sudo /opt/emc/scaleio/sdc/bin/drv_cfg --add_mdm --ip '${var.scaleio_mdm_ips}' --file /bin/emc/scaleio/drv_cfg.txt",
      "docker swarm init --advertise-addr ${vsphere_virtual_machine.swarm_master.network_interface.0.ipv4_address}",
      "echo 'y' | docker plugin install rexray/scaleio SCALEIO_ENDPOINT=https://${var.scaleio_gateway_ip}/api SCALEIO_USERNAME=${var.scaleio_username} SCALEIO_PASSWORD=${var.scaleio_password} SCALEIO_SYSTEMNAME=${var.scaleio_system_name} SCALEIO_PROTECTIONDOMAINNAME=${var.scaleio_protection_domain_name} SCALEIO_STORAGEPOOLNAME=${var.scaleio_storage_pool_name} REXRAY_LOGLEVEL=${var.rexray_log_level} REXRAY_PREEMPT=true"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }
}

resource "vsphere_virtual_machine" "swarm_worker" {
  depends_on = ["vsphere_virtual_machine.swarm_master"]
  count = "${var.swarm_worker_count}"
  name   = "swarm-worker-${count.index}"
  domain = "${var.domain}"
  datacenter = "${var.vsphere_datacenter}"
  dns_servers = ["${var.dns}"]
  cluster = "${var.vsphere_cluster}"
  vcpu   = 2
  memory = 2048

  network_interface {
    label = "${var.vsphere_port_group_1}"
  }

  network_interface {
    label = "${var.vsphere_port_group_2}"
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
      "sudo chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
      "sudo /opt/emc/scaleio/sdc/bin/drv_cfg --add_mdm --ip '${var.scaleio_mdm_ips}' --file /bin/emc/scaleio/drv_cfg.txt",
      "`docker -H=${vsphere_virtual_machine.swarm_master.network_interface.0.ipv4_address}:2375 swarm join-token worker | awk '{if(NR>1)print}'`",
      "echo 'y' | docker plugin install rexray/scaleio SCALEIO_ENDPOINT=https://${var.scaleio_gateway_ip}/api SCALEIO_USERNAME=${var.scaleio_username} SCALEIO_PASSWORD=${var.scaleio_password} SCALEIO_SYSTEMNAME=${var.scaleio_system_name} SCALEIO_PROTECTIONDOMAINNAME=${var.scaleio_protection_domain_name} SCALEIO_STORAGEPOOLNAME=${var.scaleio_storage_pool_name} REXRAY_LOGLEVEL=${var.rexray_log_level}"
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
      "docker -H=${vsphere_virtual_machine.swarm_master.network_interface.0.ipv4_address}:2375 node rm `docker -H=${vsphere_virtual_machine.swarm_master.network_interface.0.ipv4_address}:2375 node ls | grep Down | awk '{print $1;}'`"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }
}

output "master_public_ip" {
  value = "${vsphere_virtual_machine.swarm_master.network_interface.0.ipv4_address}"
}
