provider "vsphere" {
  user           = "${var.vsphere_username}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_vcenter}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter"
{
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "datastore"
{
  name = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_resource_pool" "pool"
{
  name = "${var.vsphere_cluster}"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_network" "network_corp"
{
  name = "${var.vsphere_port_group_corp}"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_network" "network_sio1"
{
  name = "${var.vsphere_port_group_sio1}"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_network" "network_sio2"
{
  name = "${var.vsphere_port_group_sio2}"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_virtual_machine" "template"
{
  name = "${var.vsphere_template}"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

# Create a single "master" swarm manager first
resource "vsphere_virtual_machine" "swarmmanager1"
{
  # Since count.index starts at 0 we increment by 1 for proper naming
  name   = "${var.vsphere_vm_name_manager}${count.index + 1}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id = "${data.vsphere_datastore.datastore.id}"
  folder = "${var.vsphere_folder}"

  num_cpus = "${var.vsphere_vcpu_manager}"
  memory = "${var.vsphere_memory_manager}"

  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface
  {
    network_id = "${data.vsphere_network.network_corp.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface
  {
    network_id = "${data.vsphere_network.network_sio1.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface
  {
    network_id = "${data.vsphere_network.network_sio2.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk
  {
    name = "${var.vsphere_vm_name_manager}${count.index + 1}.vmdk"
    size = "${data.vsphere_virtual_machine.template.disk_sizes[0]}"
    thin_provisioned = true
  }

  clone
  {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize
    {
      linux_options
      {
        host_name ="${var.vsphere_os_hostname_manager}${count.index + 1}"
        domain = "${var.domain}"
        time_zone = "America/Los_Angeles"
      }

      # Since the variable arrays start at 0 we use that as count.index
      network_interface
      {
        ipv4_address = "${var.ipv4_address_manager[count.index]}"
        ipv4_netmask = "${var.ipv4_prefix_length_manager}"
        dns_server_list = ["${var.dns}"]
      }

      network_interface
      {
        ipv4_address = "${var.ipv4_address_manager_sio1[count.index]}"
        ipv4_netmask = "${var.ipv4_prefix_length_manager}"
        dns_server_list = ["${var.dns}"]
      }

      network_interface
      {
        ipv4_address = "${var.ipv4_address_manager_sio2[count.index]}"
        ipv4_netmask = "${var.ipv4_prefix_length_manager}"
        dns_server_list = ["${var.dns}"]
      }

      ipv4_gateway = "${var.ipv4_gateway_manager}"
      dns_server_list = ["${var.dns}"]
      dns_suffix_list = ["${var.dns_search_list}"]
    }
  }

  provisioner "file"
  {
    source = "files/"
    destination = "/tmp"

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }

  provisioner "remote-exec"
  {
    inline =
    [
      "sudo chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh ${var.scaleio_mdm_ips} ${var.scaleio_gateway_ip} ${var.scaleio_username} ${var.scaleio_password} ${var.scaleio_protection_domain_name} ${var.scaleio_storage_pool_name}",
    ]

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }

  provisioner "remote-exec"
  {
    inline =
    [
      "sudo chmod +x /tmp/manager_setup.sh",
      "sudo /tmp/manager_setup.sh ${var.vsphere_os_hostname_manager} ${var.ipv4_address_manager[count.index]}",
    ]

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }
}

# Provisions any additional swarm managers based on var.swarmmanager_count
resource "vsphere_virtual_machine" "swarmmanagerx"
{
  depends_on = ["vsphere_virtual_machine.swarmmanager1"]

  # Subtract one from count since we already provisioned 1 manager
  count = "${var.swarmmanager_count - 1}"

  # count.index + 2 for proper naming (0+2 = 2)
  name   = "${var.vsphere_vm_name_manager}${count.index + 2}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id = "${data.vsphere_datastore.datastore.id}"
  folder = "${var.vsphere_folder}"

  num_cpus = "${var.vsphere_vcpu_manager}"
  memory = "${var.vsphere_memory_manager}"

  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface
  {
    network_id = "${data.vsphere_network.network_corp.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface
  {
    network_id = "${data.vsphere_network.network_sio1.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface
  {
    network_id = "${data.vsphere_network.network_sio2.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk
  {
    name = "${var.vsphere_vm_name_manager}${count.index + 2}.vmdk"
    size = "${data.vsphere_virtual_machine.template.disk_sizes[0]}"
    thin_provisioned = true
  }

  clone
  {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize
    {
      linux_options
      {
        host_name ="${var.vsphere_os_hostname_manager}${count.index + 2}"
        domain = "${var.domain}"
        time_zone = "America/Los_Angeles"
      }

      # Since we use the same variable array to hold all manager IPs we add
      # +1 since the index of 0 was used for the "master" manager
      network_interface
      {
        ipv4_address = "${var.ipv4_address_manager[count.index + 1]}"
        ipv4_netmask = "${var.ipv4_prefix_length_manager}"
        dns_server_list = ["${var.dns}"]
      }

      network_interface
      {
        ipv4_address = "${var.ipv4_address_manager_sio1[count.index + 1]}"
        ipv4_netmask = "${var.ipv4_prefix_length_manager}"
        dns_server_list = ["${var.dns}"]
      }

      network_interface
      {
        ipv4_address = "${var.ipv4_address_manager_sio2[count.index + 1]}"
        ipv4_netmask = "${var.ipv4_prefix_length_manager}"
        dns_server_list = ["${var.dns}"]
      }

      ipv4_gateway = "${var.ipv4_gateway_manager}"
      dns_server_list = ["${var.dns}"]
      dns_suffix_list = ["${var.dns_search_list}"]
    }
  }

  provisioner "file"
  {
    source = "files/"
    destination = "/tmp"

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }

  provisioner "remote-exec"
  {
    inline =
    [
      "sudo chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh ${var.scaleio_mdm_ips} ${var.scaleio_gateway_ip} ${var.scaleio_username} ${var.scaleio_password} ${var.scaleio_protection_domain_name} ${var.scaleio_storage_pool_name}",
    ]

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }

  provisioner "remote-exec"
  {
    inline =
    [
      "sudo chmod +x /tmp/manager_setup.sh",
      "sudo /tmp/manager_setup.sh ${var.vsphere_os_hostname_manager} ${var.ipv4_address_manager[count.index]}",
    ]

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }
}

resource "vsphere_virtual_machine" "swarmworker"
{
  depends_on = ["vsphere_virtual_machine.swarmmanager1"]
  count = "${var.swarmworker_count}"
  name   = "${var.vsphere_vm_name_worker}${count.index + 1}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id = "${data.vsphere_datastore.datastore.id}"
  folder = "${var.vsphere_folder}"

  num_cpus = "${var.vsphere_vcpu_worker}"
  memory = "${var.vsphere_memory_worker}"

  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface
  {
    network_id = "${data.vsphere_network.network_corp.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface
  {
    network_id = "${data.vsphere_network.network_sio1.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface
  {
    network_id = "${data.vsphere_network.network_sio2.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk
  {
    name = "${var.vsphere_vm_name_worker}${count.index + 1}.vmdk"
    size = "${data.vsphere_virtual_machine.template.disk_sizes[0]}"
    thin_provisioned = true
  }

  clone
  {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize
    {
      linux_options
      {
        host_name ="${var.vsphere_os_hostname_worker}${count.index + 1}"
        domain = "${var.domain}"
        time_zone = "America/Los_Angeles"
      }

      network_interface
      {
        ipv4_address = "${var.ipv4_address_worker[count.index]}"
        ipv4_netmask = "${var.ipv4_prefix_length_worker}"
        dns_server_list = ["${var.dns}"]
      }

      network_interface
      {
        ipv4_address = "${var.ipv4_address_worker_sio1[count.index]}"
        ipv4_netmask = "${var.ipv4_prefix_length_manager}"
        dns_server_list = ["${var.dns}"]
      }

      network_interface
      {
        ipv4_address = "${var.ipv4_address_worker_sio2[count.index]}"
        ipv4_netmask = "${var.ipv4_prefix_length_manager}"
        dns_server_list = ["${var.dns}"]
      }

      ipv4_gateway = "${var.ipv4_gateway_worker}"
      dns_server_list = ["${var.dns}"]
      dns_suffix_list = ["${var.dns_search_list}"]
    }
  }

  provisioner "file"
  {
    source = "files/"
    destination = "/tmp"

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }

  provisioner "remote-exec"
  {
    inline =
    [
      "sudo chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh ${var.scaleio_mdm_ips} ${var.scaleio_gateway_ip} ${var.scaleio_username} ${var.scaleio_password} ${var.scaleio_protection_domain_name} ${var.scaleio_storage_pool_name}",
    ]

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }

  provisioner "remote-exec"
  {
    inline =
    [
      "sudo chmod +x /tmp/worker_setup.sh",
      "sudo /tmp/worker_setup.sh",
    ]

    connection
    {
      type = "ssh"
      user = "${var.vm_ssh_username}"
      password = "${var.vm_ssh_password}"
    }
  }
}
