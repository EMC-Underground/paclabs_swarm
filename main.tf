provider "vsphere" {
  user           = "${var.vsphere_username}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_vcenter}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "datastore" {
  name = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name = "${var.vsphere_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name = "${var.vsphere_port_group_1}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vsphere_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "swarm_master" {
  name   = "swarm-master"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  guest_id = "ubuntu64Guest"
  num_cpus   = 2
  memory = 4096

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    name             = "swarm-master.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "swarm-master"
        domain    = "${var.domain}"
      }

      network_interface { }
    }
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
      "docker swarm init --advertise-addr ${vsphere_virtual_machine.swarm_master.default_ip_address}",
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
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  guest_id = "ubuntu64Guest"
  sync_time_with_host = true
  num_cpus   = 2
  memory = 2048

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    name             = "swarm-worker-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "swarm-worker-${count.index}"
        domain    = "${var.domain}"
      }

      network_interface { }
    }
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
      "`docker -H=${vsphere_virtual_machine.swarm_master.default_ip_address}:2375 swarm join-token worker | awk '{if(NR>1)print}'`",
      "echo 'y' | docker plugin install rexray/scaleio SCALEIO_ENDPOINT=https://${var.scaleio_gateway_ip}/api SCALEIO_USERNAME=${var.scaleio_username} SCALEIO_PASSWORD=${var.scaleio_password} SCALEIO_SYSTEMNAME=${var.scaleio_system_name} SCALEIO_PROTECTIONDOMAINNAME=${var.scaleio_protection_domain_name} SCALEIO_STORAGEPOOLNAME=${var.scaleio_storage_pool_name} REXRAY_LOGLEVEL=${var.rexray_log_level} REXRAY_PREEMPT=true"
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
      "docker -H=${vsphere_virtual_machine.swarm_master.default_ip_address}:2375 node rm `docker -H=${vsphere_virtual_machine.swarm_master.default_ip_address}:2375 node ls | grep Down | awk '{print $1;}'`"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Password#1"
    }
  }
}

output "master_public_ip" {
  value = "${vsphere_virtual_machine.swarm_master.default_ip_address}"
}
