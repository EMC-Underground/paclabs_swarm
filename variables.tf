variable "vsphere_password" {
    description = "The vsphere password"
}

variable "vsphere_username" {
    description = "Your vSphere username"
}

variable "vsphere_vcenter" {
    description = "vCenter IP or FQDN"
}

variable "dns" {
    description = "Local DNS"
}

variable "domain" {
    description = "Local domain suffix"
}

variable "port_group" {
    description = "The vsphere port group the swarm will reside on"
}

variable "vsphere_datastore" {
    description = "The vsphere datastore to deploy the swarm to"
}

variable "swarm_worker_count" {
    description = "How many workers in the swarm"
}
