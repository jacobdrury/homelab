variable "unifi_api_key" {
  description = "Local UniFi Network API key (UDM Integrations)"
  type        = string
  sensitive   = true
}

variable "unifi_api_url" {
  description = "UniFi OS console URL (Homelab gateway — reachable via Tailscale Homelab route)"
  type        = string
  default     = "https://192.168.5.1"
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
