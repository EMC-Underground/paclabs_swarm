variable "vm_ssh_username"
{
  description = "VM SSH username"
}

variable "vm_ssh_password"
{
  description = "VM SSH password"
}

variable "vsphere_username" {
    description = "Your vSphere username"
}

variable "vsphere_password" {
    description = "The vsphere password"
}

variable "vsphere_vcenter" {
    description = "vCenter IP or FQDN"
}

variable "vsphere_datacenter" {
    description = "The vsphere datacenter to deploy on"
}

variable "vsphere_datastore" {
    description = "The vsphere datastore to deploy on"
}

variable "vsphere_cluster" {
    description = "The vsphere cluster to deploy on"
}

variable "vsphere_port_group_corp" {
    description = "The vsphere port group the VM will use for management/corp"
}

variable "vsphere_port_group_sio1" {
    description = "The vSphere port group used for ScaleIO 1"
}

variable "vsphere_port_group_sio2" {
    description = "The vSphere port group used for ScaleIO 2"
}

variable "vsphere_template" {
    description = "The VM template to use"
}

variable "vsphere_vm_name_manager" {
    description = "The name of the swarm manager VM to deploy"
}

variable "vsphere_vm_name_worker" {
    description = "The name of the swarm worker VM to deploy"
}

variable "vsphere_os_hostname_manager" {
    description = "The hostname of the swarm manager VM to deploy"
}

variable "vsphere_os_hostname_worker" {
    description = "The hostname of the swarm worker VM to deploy"
}

variable "vsphere_folder" {
    description = "The vsphere folder to put VM into"
}

variable "vsphere_vcpu_manager" {
    description = "The # of vCPUs for the swarm manager VM"
}

variable "vsphere_vcpu_worker" {
    description = "The # of vCPUs for the swarm manager VM"
}

variable "vsphere_memory_manager" {
    description = "The memory for the swarm manager VM"
}

variable "vsphere_memory_worker" {
    description = "The memory for the swarm manager VM"
}

variable "dns" {
    type = "list"
    description = "Local DNS servers"
}

variable "dns_search_list" {
    type = "list"
    description = "DNS suffixes to add for DNS search"
}

variable "domain" {
    description = "Local domain suffix"
}

variable "ipv4_address_manager" {
    type = "list"
    description = "Static IPv4 address for corp management"
}

variable "ipv4_address_manager_sio1" {
    type = "list"
    description = "Static IPv4 address for SDC-MDM first VLAN"
}

variable "ipv4_address_manager_sio2" {
    type = "list"
    description = "Static IPv4 address for SDC-MDM second VLAN"
}

variable "ipv4_prefix_length_manager" {
    description = "Prefix length of IPv4 address"
}

variable "ipv4_gateway_manager" {
    description = "IPv4 gateway"
}

variable "ipv4_address_worker" {
    type = "list"
    description = "Static IPv4 address for corp management"
}

variable "ipv4_address_worker_sio1" {
    type = "list"
    description = "Static IPv4 address for SDC-MDM first VLAN"
}

variable "ipv4_address_worker_sio2" {
    type = "list"
    description = "Static IPv4 address for SDC-MDM second VLAN"
}

variable "ipv4_prefix_length_worker" {
    description = "Prefix length of IPv4 address"
}

variable "ipv4_gateway_worker" {
    description = "IPv4 gateway"
}

variable "swarmmanager_count" {
    description = "# of swarm managers"
}

variable "swarmworker_count" {
    description = "# of swarm worker"
}
