resource "unifi_network" "homelab" {
  name         = var.homelab_network_name
  purpose      = "corporate"
  subnet       = var.homelab_subnet
  vlan_id      = var.homelab_vlan_id
  dhcp_enabled = true
  dhcp_start   = var.homelab_dhcp_start
  dhcp_stop    = var.homelab_dhcp_stop

  # Pi-hole on VLAN 1 until k8s cutover
  dhcp_dns = ["192.168.1.11"]

  # Omit multicast_dns — filipowm/unifi maps it to mdns_enabled but the UDM does not
  # persist true on this network (perpetual plan drift). Enable mDNS in UI if needed.
}
