variable "block_lists" {
  description = "Gravity block list subscriptions (type = block)"
  type = map(object({
    address = string
    enabled = optional(bool, true)
    comment = optional(string, "")
  }))
  default = {}
}

variable "allow_lists" {
  description = "Gravity allow list subscriptions (type = allow)"
  type = map(object({
    address = string
    enabled = optional(bool, true)
    comment = optional(string, "")
  }))
  default = {}
}

variable "domains" {
  description = "Per-domain allow/deny rules (exact or regex)"
  type = map(object({
    domain  = string
    type    = string # allow | deny
    kind    = string # exact | regex
    enabled = optional(bool, true)
    comment = optional(string, "")
  }))
  default = {}
}

variable "local_dns" {
  description = "Pi-hole local DNS A records (LAN hostnames not in Cloudflare)"
  type        = map(string)
  default     = {}
}

variable "dns_upstreams" {
  description = "Ordered upstream resolvers Pi-hole forwards to"
  type        = list(string)
  default     = []
}
