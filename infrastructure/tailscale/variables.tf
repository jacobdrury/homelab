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
  description = "Create reusable preauth key (tag:k8s) for Tailscale k8s operator — secret in tfstate only"
  type        = bool
  default     = true
}
