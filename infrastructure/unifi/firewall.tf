# Zone-Based Firewall (UniFi OS 9+). Requires ZBF enabled on the UDM before apply:
# https://help.ui.com/hc/en-us/articles/28223082254743-Migrating-to-Zone-Based-Firewalls-in-UniFi
#
# Policy intent:
#   Drury → Homelab: allow all (mgmt + NFS + Pi-hole DNS VIP)
#   Homelab → Drury: transitional Envoy → Proxmox only
#   Homelab → IoT: allow all (Home Assistant on k8s must reach devices)
#   Homelab → Guest/Camera (Isolated): deny
#   IoT / Isolated → Homelab Pi-hole DNS VIP (.22): DNS only
#   Homelab → Internet: rely on External zone defaults (allow)

resource "unifi_firewall_group" "dns" {
  name    = "DNS"
  type    = "port-group"
  members = ["53"]
}

resource "unifi_firewall_group" "proxmox_https" {
  name    = "Proxmox HTTPS"
  type    = "port-group"
  members = ["8006"]
}

# Envoy VIP — IoT devices calling back to https://homeassistant.lab (webhooks, etc.).
resource "unifi_firewall_group" "envoy_http" {
  name    = "Envoy HTTP"
  type    = "port-group"
  members = ["80", "443"]
}

# Homelab must be its own zone — same zone as Drury would allow unrestricted lateral traffic.
resource "unifi_firewall_zone" "drury" {
  name     = "Drury"
  networks = [unifi_network.lan["drury"].id]
}

resource "unifi_firewall_zone" "homelab" {
  name     = "Homelab"
  networks = [unifi_network.homelab.id]
}

# IoT is separate so Homelab (HA) can reach devices without opening Guest/Camera.
resource "unifi_firewall_zone" "iot" {
  name     = "IoT"
  networks = [unifi_network.lan["iot"].id]
}

resource "unifi_firewall_zone" "isolated" {
  name = "Isolated"
  networks = [
    unifi_network.lan["guest"].id,
    unifi_network.lan["camera"].id,
  ]
}

# Trusted LAN can reach the lab (arr NFS, Proxmox mgmt into Homelab, Pi-hole DNS VIP, etc.).
resource "unifi_firewall_zone_policy" "drury_to_homelab" {
  name                      = "Allow Drury to Homelab"
  action                    = "ALLOW"
  protocol                  = "all"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"

  source = {
    zone_id = unifi_firewall_zone.drury.id
  }

  destination = {
    zone_id = unifi_firewall_zone.homelab.id
  }
}

resource "unifi_firewall_zone_policy" "homelab_to_proxmox" {
  name                      = "Allow Homelab HTTPS to Proxmox"
  action                    = "ALLOW"
  protocol                  = "tcp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "Envoy transitional https://proxmox.lab → homelab02 :8006"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.drury.id
    ips           = [local.lab.services.proxmox.host]
    port_group_id = unifi_firewall_group.proxmox_https.id
  }
}

# Home Assistant (and other Homelab workloads) must reach IoT devices (ESPHome, Hue, Lutron, …).
# auto_allow_return_traffic covers device replies on HA-initiated sessions (the common case).
resource "unifi_firewall_zone_policy" "homelab_to_iot" {
  name                      = "Allow Homelab to IoT"
  action                    = "ALLOW"
  protocol                  = "all"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "HA on k8s → IoT VLAN devices (ESPHome, bridges, etc.)"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id = unifi_firewall_zone.iot.id
  }
}

# Device-initiated callbacks to HA via Envoy (https://homeassistant.lab → VIP .21).
# ClusterIP is not reachable from IoT; public lab URLs terminate on Envoy.
resource "unifi_firewall_zone_policy" "iot_to_homelab_envoy" {
  name                      = "Allow IoT to Homelab Envoy"
  action                    = "ALLOW"
  protocol                  = "tcp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "IoT webhooks/callbacks → Envoy VIP (homeassistant.lab, etc.)"

  source = {
    zone_id = unifi_firewall_zone.iot.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.homelab.id
    ips           = [local.lab.networks.homelab.hosts.envoy.ip]
    port_group_id = unifi_firewall_group.envoy_http.id
  }
}

resource "unifi_firewall_zone_policy" "homelab_to_isolated_block" {
  name        = "Block Homelab to Isolated"
  action      = "BLOCK"
  protocol    = "all"
  enabled     = true
  ip_version  = "IPV4"
  description = "Homelab must not initiate to Guest / Camera"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id = unifi_firewall_zone.isolated.id
  }
}

# IoT + Guest/Camera → k8s Pi-hole DNS VIP on Homelab.
resource "unifi_firewall_zone_policy" "iot_to_pihole_dns" {
  name                      = "Allow IoT DNS to Pi-hole"
  action                    = "ALLOW"
  protocol                  = "tcp_udp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "IoT → Pi-hole DNS VIP 192.168.5.22"

  source = {
    zone_id = unifi_firewall_zone.iot.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.homelab.id
    ips           = [local.lab.services.pihole.host]
    port_group_id = unifi_firewall_group.dns.id
  }
}

resource "unifi_firewall_zone_policy" "isolated_to_pihole_dns" {
  name                      = "Allow Isolated DNS to Pi-hole"
  action                    = "ALLOW"
  protocol                  = "tcp_udp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "Guest/Camera → Pi-hole DNS VIP 192.168.5.22"

  source = {
    zone_id = unifi_firewall_zone.isolated.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.homelab.id
    ips           = [local.lab.services.pihole.host]
    port_group_id = unifi_firewall_group.dns.id
  }
}

# Ensure allows evaluate before broader zone-pair defaults.
resource "unifi_firewall_zone_policy_order" "homelab_to_drury" {
  source_zone_id      = unifi_firewall_zone.homelab.id
  destination_zone_id = unifi_firewall_zone.drury.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.homelab_to_proxmox.id,
  ]
}

resource "unifi_firewall_zone_policy_order" "drury_to_homelab" {
  source_zone_id      = unifi_firewall_zone.drury.id
  destination_zone_id = unifi_firewall_zone.homelab.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.drury_to_homelab.id,
  ]
}

resource "unifi_firewall_zone_policy_order" "homelab_to_iot" {
  source_zone_id      = unifi_firewall_zone.homelab.id
  destination_zone_id = unifi_firewall_zone.iot.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.homelab_to_iot.id,
  ]
}

resource "unifi_firewall_zone_policy_order" "iot_to_homelab" {
  source_zone_id      = unifi_firewall_zone.iot.id
  destination_zone_id = unifi_firewall_zone.homelab.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.iot_to_pihole_dns.id,
    unifi_firewall_zone_policy.iot_to_homelab_envoy.id,
  ]
}

resource "unifi_firewall_zone_policy_order" "isolated_to_homelab" {
  source_zone_id      = unifi_firewall_zone.isolated.id
  destination_zone_id = unifi_firewall_zone.homelab.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.isolated_to_pihole_dns.id,
  ]
}

resource "unifi_firewall_zone_policy_order" "homelab_to_isolated" {
  source_zone_id      = unifi_firewall_zone.homelab.id
  destination_zone_id = unifi_firewall_zone.isolated.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.homelab_to_isolated_block.id,
  ]
}
