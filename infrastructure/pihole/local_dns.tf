# LAN-only hostnames — not in Cloudflare (see dns_forward.tf for *.lab.jacobdrury.com).
resource "pihole_dns_record" "local" {
  for_each = var.local_dns

  domain = each.key
  ip     = each.value
}
