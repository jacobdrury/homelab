# LAN networks — DHCP DNS points at Homelab Pi-hole VIP (Cilium L2 .22).
# Existing UniFi network IDs live in lab.yaml (unifi_id) for import blocks.

locals {
  pihole_dhcp_dns = [local.lab.services.pihole.host]

  # Networks other than Homelab (already managed below with hosts map).
  lan_networks = {
    drury  = local.lab.networks.drury
    iot    = local.lab.networks.iot
    guest  = local.lab.networks.guest
    camera = local.lab.networks.camera
  }
}

import {
  for_each = local.lan_networks
  to       = unifi_network.lan[each.key]
  id       = each.value.unifi_id
}

resource "unifi_network" "lan" {
  for_each = local.lan_networks

  name         = each.value.unifi_name
  purpose      = "corporate"
  subnet       = each.value.gateway_cidr
  dhcp_enabled = true
  dhcp_start   = each.value.dhcp.start
  dhcp_stop    = each.value.dhcp.stop
  dhcp_dns     = local.pihole_dhcp_dns

  # Native LAN (Drury) has no VLAN tag — omit vlan_id when unset.
  vlan_id = try(each.value.vlan_id, null)

  # Match live UDM: RA on for these VLANs (Homelab keeps provider default / none).
  ipv6_ra_enable         = true
  ipv6_ra_valid_lifetime = 86400

  # Reflect mDNS on trusted + IoT. Guest/Camera stay off (Isolated).
  # Needed for HomeKit / Chromecast / ESPHome discovery across VLANs.
  multicast_dns = contains(["drury", "iot"], each.key)
}

resource "unifi_network" "homelab" {
  name         = local.lab.networks.homelab.unifi_name
  purpose      = "corporate"
  subnet       = local.lab.networks.homelab.gateway_cidr
  vlan_id      = local.lab.networks.homelab.vlan_id
  dhcp_enabled = true
  dhcp_start   = local.lab.networks.homelab.dhcp.start
  dhcp_stop    = local.lab.networks.homelab.dhcp.stop

  dhcp_dns = local.pihole_dhcp_dns

  # HA (Homelab) must hear IoT HomeKit/zeroconf ads — UniFi reflects between
  # networks that both have Multicast DNS on. Guest/Camera stay off.
  # Older UDM builds sometimes dropped this flag; re-apply if the UI shows off.
  multicast_dns = true
}
