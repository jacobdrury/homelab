# Infra hostnames on Homelab VLAN 5 (RFC1918 — DNS only, not proxied).
# Apps (*.lab) get additional records in Phase 2+ (Envoy / external-dns).

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

# Transitional pre-k8s aliases (Drury VLAN guests). Retire at Phase 3 cutover.
resource "cloudflare_dns_record" "lab_transitional" {
  for_each = local.transitional_lab_hosts

  zone_id = data.cloudflare_zone.jacobdrury.id
  name    = "${each.key}.lab"
  type    = "A"
  content = each.value
  proxied = false
  ttl     = 1
  comment = "Transitional *.lab — ${each.key} (pre-k8s)"
}
