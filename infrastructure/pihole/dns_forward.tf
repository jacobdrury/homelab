# Forward *.lab.jacobdrury.com to Cloudflare — authoritative zone is infrastructure/dns/.
# Cloudflare returns RFC1918 A records (grey cloud); external-dns app records appear automatically.
locals {
  lab_zone = "lab.jacobdrury.com"
  lab_zone_forward_lines = [
    for upstream in var.lab_zone_forward_upstreams :
    "server=/${local.lab_zone}/${upstream}"
  ]
}

resource "pihole_setting" "lab_zone_forward" {
  key   = "misc.dnsmasq_lines"
  value = jsonencode(local.lab_zone_forward_lines)
}
