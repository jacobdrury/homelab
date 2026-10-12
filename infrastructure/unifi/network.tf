# LAN DHCP DNS = each network's gateway. UniFi domain-based VPN traffic routes
# require clients to use the gateway as DNS; the gateway forwards to Pi-hole
# (WAN DNS on Internet 1). Existing UniFi network IDs live in lab.yaml (unifi_id).

locals {
  # Networks other than Homelab (already managed below with hosts map).
  lan_networks = {
    drury  = local.lab.networks.drury
    iot    = local.lab.networks.iot
    guest  = local.lab.networks.guest
    camera = local.lab.networks.camera
  }

  # DHCP option 6: advertise the VLAN gateway so UniFi can match domain routes.
  gateway_dhcp_dns = {
    for key, net in local.lan_networks :
    key => [split("/", net.gateway_cidr)[0]]
  }

  # AT&T currently delegates a single /64 — only one LAN can take PD.
  # Drury (trusted clients) gets it; other VLANs stay IPv4-only until a larger prefix arrives.
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
  dhcp_dns     = local.gateway_dhcp_dns[each.key]

  # Native LAN (Drury) has no VLAN tag — omit vlan_id when unset.
  vlan_id = try(each.value.vlan_id, null)

  # IPv6: only Drury uses WAN PD (single /64 from AT&T). Other VLANs stay off
  # so RA does not advertise empty/ULA prefixes.
  ipv6_interface_type = each.key == "drury" ? "pd" : "none"
  ipv6_pd_interface   = each.key == "drury" ? "wan" : null
  ipv6_pd_prefixid    = each.key == "drury" ? "0" : null
  ipv6_ra_enable      = each.key == "drury"
  ipv6_ra_priority    = each.key == "drury" ? "high" : null

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

  dhcp_dns = [split("/", local.lab.networks.homelab.gateway_cidr)[0]]

  # No spare /64 under current AT&T delegation — keep Homelab IPv4-only for now.
  ipv6_interface_type = "none"
  ipv6_ra_enable      = false

  # HA (Homelab) must hear IoT HomeKit/zeroconf ads — UniFi reflects between
  # networks that both have Multicast DNS on. Guest/Camera stay off.
  # Older UDM builds sometimes dropped this flag; re-apply if the UI shows off.
  multicast_dns = true
}

# Primary WAN — DNS upstream is Pi-hole so client → gateway → Pi-hole still
# filters while UniFi sees queries for VPN domain routes.
# UniFi OS needs wan_dns_preference=manual (provider has no attribute); set once
# in the UI/API if WAN DNS reverts to Auto.
import {
  to = unifi_network.wan_primary
  id = local.lab.networks.wan_primary.unifi_id
}

resource "unifi_network" "wan_primary" {
  name             = local.lab.networks.wan_primary.unifi_name
  purpose          = "wan"
  wan_networkgroup = "WAN"
  wan_type         = "dhcp"
  wan_type_v6      = "dhcpv6"
  wan_dns          = [local.lab.services.pihole.host]

  # Import brings ISP/controller defaults; only wan_dns + IPv6 WAN type are intentional.
  lifecycle {
    ignore_changes = [
      dhcp_lease,
      dhcp_v6_dns_auto,
      dhcp_v6_lease,
      ipv6_ra_preferred_lifetime,
      ipv6_ra_valid_lifetime,
    ]
  }
}
