variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS Edit on jacobdrury.com"
  type        = string
  sensitive   = true
}

variable "zone_name" {
  description = "Cloudflare zone name"
  type        = string
  default     = "jacobdrury.com"
}

variable "zone_id" {
  description = "Cloudflare zone ID for jacobdrury.com"
  type        = string
  default     = "547747653c5a253f3e6162a748925d47"
}
