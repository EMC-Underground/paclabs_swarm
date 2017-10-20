variable "vsphere_password" {
    description = "The vsphere password"
}

variable "vsphere_username" {
    description = "Your vSphere username"
}

variable "vsphere_vcenter" {
    description = "vCenter IP or FQDN"
}

variable "vsphere_datastore" {
    description = "The vsphere datastore to deploy the swarm to"
}

variable "vsphere_datacenter" {
    description = "The vsphere datacenter to deploy the swarm to"
}

variable "vsphere_cluster" {
    description = "The vsphere cluster to deploy the swarm to"
}

variable "vsphere_template" {
    description = "The template to use for the creation of the docker swarm nodes"
}

variable "dns" {
    description = "Local DNS"
}

variable "domain" {
    description = "Local domain suffix"
}

variable "vsphere_port_group_1" {
    description = "The vsphere port group the swarm will reside on"
}

variable "vsphere_port_group_2" {
    description = "The vSphere port group used for data if necessary (Optional)"
}

variable "swarm_worker_count" {
    description = "How many workers in the swarm"
    default = 4
}
