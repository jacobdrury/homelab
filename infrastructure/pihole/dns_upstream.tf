resource "pihole_dns_upstreams" "main" {
  count = length(var.dns_upstreams) > 0 ? 1 : 0

  upstreams = var.dns_upstreams
}
