# Infra hostnames on Homelab VLAN 5 (RFC1918 — DNS only, not proxied).
# Apps (*.lab) get additional records in Phase 2+ (Envoy / external-dns).

locals {
  lab_hosts = {
    scarif = "192.168.5.10"
    yavin  = "192.168.5.11"
    k8s    = "192.168.5.11"
    hoth   = "192.168.5.12"
    endor  = "192.168.5.13"
  }
}

resource "cloudflare_dns_record" "lab_host" {
  for_each = local.lab_hosts

  zone_id = data.cloudflare_zone.jacobdrury.id
  name    = "${each.key}.lab"
  type    = "A"
  content = each.value
  proxied = false
  ttl     = 1
  comment = "Homelab infra — ${each.key} (VLAN 5)"
}
