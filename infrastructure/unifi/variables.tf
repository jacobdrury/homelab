variable "unifi_api_key" {
  description = "Local UniFi Network API key (UDM Integrations)"
  type        = string
  sensitive   = true
}

variable "unifi_api_url" {
  description = "UniFi OS console URL"
  type        = string
  default     = "https://192.168.1.1"
}

variable "unifi_allow_insecure" {
  description = "Skip TLS verification for local controller cert"
  type        = bool
  default     = true
}

variable "unifi_site" {
  description = "UniFi site name"
  type        = string
  default     = "default"
}

variable "homelab_network_name" {
  type    = string
  default = "Homelab"
}

variable "homelab_vlan_id" {
  type    = number
  default = 5
}

variable "homelab_subnet" {
  description = "Gateway CIDR (UniFi convention: .1 is gateway)"
  type        = string
  default     = "192.168.5.1/24"
}

variable "homelab_dhcp_start" {
  type    = string
  default = "192.168.5.6"
}

variable "homelab_dhcp_stop" {
  type    = string
  default = "192.168.5.254"
}

variable "drury_network_name" {
  type    = string
  default = "Drury"
}
