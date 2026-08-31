resource "unifi_network" "homelab" {
  name         = local.lab.networks.homelab.unifi_name
  purpose      = "corporate"
  subnet       = local.lab.networks.homelab.gateway_cidr
  vlan_id      = local.lab.networks.homelab.vlan_id
  dhcp_enabled = true
  dhcp_start   = local.lab.networks.homelab.dhcp.start
  dhcp_stop    = local.lab.networks.homelab.dhcp.stop

  dhcp_dns = [local.lab.services.pihole.host]

  # Omit multicast_dns — filipowm/unifi maps it to mdns_enabled but the UDM does not
  # persist true on this network (perpetual plan drift). Enable mDNS in UI if needed.
}
