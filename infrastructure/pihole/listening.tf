# Permit DNS from other VLANs (Homelab / Isolated). LOCAL only answers the Pi-hole subnet.
resource "pihole_setting" "dns_listening_mode" {
  key   = "dns.listeningMode"
  value = jsonencode("ALL")
}
