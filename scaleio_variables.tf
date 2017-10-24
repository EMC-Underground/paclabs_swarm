variable "scaleio_gateway_ip" {
    description = "The IP address of the ScaleiO Cluster Gateway"
}

variable "scaleio_mdm_ips" {
    description = "The IP addresses of the scaleio MDM servers found with scli --query_cluster"
}

variable "scaleio_username" {
    description = "The username RexRay will use to connect to the ScaleIO cluster with"
}

variable "scaleio_password" {
    description = "The password RexRay will use to connect to the ScaleIO cluster with"
}

variable "scaleio_system_name" {
    description = "The ID number of the scaleio system found with scli --query_all"
}

variable "scaleio_protection_domain_name" {
    description = "The protection domain name rexray will connect to scli --query_all"
}

variable "scaleio_storage_pool_name" {
    description = "The storage pool rexray will provision and connect storage from scli --query_all"
}

variable "rexray_log_level" {
    description = "The rexray loglevel"
    default="debug"
}
