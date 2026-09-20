variable "unifi_api_key" {
  description = "Local UniFi Network API key (UDM Integrations)"
  type        = string
  sensitive   = true
}

variable "unifi_api_url" {
  description = "UniFi OS console URL override (default: https://Homelab gateway from lab.yaml)"
  type        = string
  default     = null
  nullable    = true
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
