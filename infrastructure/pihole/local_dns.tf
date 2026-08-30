# LAN resolution for homelab infra — mirrors infrastructure/dns/lab.tf (Cloudflare is authoritative public).
locals {
  lab_dns_defaults = {
    "scarif.lab.jacobdrury.com" = "192.168.5.10"
    "yavin.lab.jacobdrury.com"  = "192.168.5.11"
    "k8s.lab.jacobdrury.com"    = "192.168.5.11"
    "hoth.lab.jacobdrury.com"   = "192.168.5.12"
    "endor.lab.jacobdrury.com"  = "192.168.5.13"
  }
}

resource "pihole_dns_record" "lab" {
  for_each = merge(local.lab_dns_defaults, var.local_dns)

  domain = each.key
  ip     = each.value
}
