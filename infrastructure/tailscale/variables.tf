variable "acl_external_link" {
  description = "Shown in Tailscale admin when policy is externally managed"
  type        = string
  default     = "https://github.com/jacobdrury/homelab/blob/main/infrastructure/tailscale/acl.tf"
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
  description = "Create reusable preauth key (tag:k8s) for Phase 2 operator — secret in tfstate only (OAuth preferred for Helm)"
  type        = bool
  default     = true
}

variable "homelab_route_via_k8s" {
  description = "When true, drop Homelab CIDR from interim homelab02 routes (k8s Connector prd-homelab-router owns it)"
  type        = bool
  default     = false
}

variable "manage_k8s_subnet_router" {
  description = "Manage key expiry + approved routes on the k8s Connector device"
  type        = bool
  default     = false
}

variable "k8s_subnet_router_hostname" {
  description = "MagicDNS hostname of the Connector subnet router (must match Connector.spec.hostname)"
  type        = string
  default     = "prd-homelab-router"
}
