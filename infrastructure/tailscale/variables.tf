variable "lab_zone" {
  description = "Split DNS domain for lab hostnames (must match Cloudflare zone suffix)"
  type        = string
  default     = "lab.jacobdrury.com"
}

variable "lab_split_dns_nameservers" {
  description = "Resolvers for lab_zone — Cloudflare public DNS returns authoritative RFC1918 A records"
  type        = set(string)
  default     = ["1.1.1.1", "1.0.0.1"]
}

variable "acl_external_link" {
  description = "Shown in Tailscale admin when policy is externally managed"
  type        = string
  default     = "https://github.com/jacobdrury/homelab/blob/main/infrastructure/tailscale/acl.tf"
}

variable "subnet_router_hostname" {
  description = "Tailscale short hostname of the interim subnet router (homelab02 until k8s operator)"
  type        = string
  default     = "homelab02"
}

variable "homelab_subnet_route" {
  description = "Homelab VLAN — required for remote *.lab (scarif, k8s, …)"
  type        = string
  default     = "192.168.5.0/24"
}

variable "drury_subnet_route" {
  description = "Drury LAN — interim only (Pi-hole, Proxmox); disable when pc black leaves lab"
  type        = string
  default     = "192.168.1.0/24"
}

variable "enable_drury_subnet_route" {
  description = "Approve Drury route on interim subnet router (homelab02)"
  type        = bool
  default     = true
}

variable "manage_subnet_router" {
  description = "Manage homelab02 routes + key expiry via API (device must advertise routes for traffic)"
  type        = bool
  default     = true
}

variable "create_k8s_operator_auth_key" {
  description = "Create reusable preauth key (tag:k8s) for Tailscale k8s operator — secret in tfstate only"
  type        = bool
  default     = true
}
