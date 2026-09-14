# Zone-Based Firewall (UniFi OS 9+). Requires ZBF enabled on the UDM before apply:
# https://help.ui.com/hc/en-us/articles/28223082254743-Migrating-to-Zone-Based-Firewalls-in-UniFi
#
# Policy intent:
#   Drury → Homelab: allow all (mgmt + NFS)
#   Homelab → Drury: DNS to Pi-hole + transitional Envoy targets (Pi-hole / Proxmox)
#   Homelab → IoT: allow all (Home Assistant on k8s must reach devices)
#   Homelab → Guest/Camera (Isolated): deny
#   IoT / Isolated → Pi-hole: DNS only
#   Homelab → Internet: rely on External zone defaults (allow)

resource "unifi_firewall_group" "dns" {
  name    = "DNS"
  type    = "port-group"
  members = ["53"]
}

# Envoy (Homelab) → remaining legacy UIs (Pi-hole / Proxmox).
resource "unifi_firewall_group" "pihole_http" {
  name    = "Pi-hole HTTP"
  type    = "port-group"
  members = ["80"]
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
  networks = [data.unifi_network.drury.id]
}

resource "unifi_firewall_zone" "homelab" {
  name     = "Homelab"
  networks = [unifi_network.homelab.id]
}

# IoT is separate so Homelab (HA) can reach devices without opening Guest/Camera.
resource "unifi_firewall_zone" "iot" {
  name     = "IoT"
  networks = [data.unifi_network.iot.id]
}

resource "unifi_firewall_zone" "isolated" {
  name = "Isolated"
  networks = [
    data.unifi_network.guest.id,
    data.unifi_network.camera.id,
  ]
}

# Trusted LAN can reach the lab (arr NFS, Proxmox mgmt into Homelab, etc.).
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

# Homelab → Drury: Pi-hole DNS + transitional Envoy proxy targets.
resource "unifi_firewall_zone_policy" "homelab_to_pihole_dns" {
  name                      = "Allow Homelab DNS to Pi-hole"
  action                    = "ALLOW"
  # Port-group + tcp_udp did not pass UDP/53 from Homelab (hostNetwork also timed out;
  # TCP/53 and HTTP/80 worked). Allow all IP protocols to the Pi-hole host so node DNS
  # works; tighten again after Pi-hole moves to Homelab/k8s.
  protocol                  = "all"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "Homelab → Pi-hole host (DNS UDP was blocked with port-group)"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id = unifi_firewall_zone.drury.id
    ips     = [local.lab.services.pihole.host]
  }
}

resource "unifi_firewall_zone_policy" "homelab_to_pihole_http" {
  name                      = "Allow Homelab HTTP to Pi-hole"
  action                    = "ALLOW"
  protocol                  = "tcp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "Envoy transitional https://pihole.lab → LXC :80"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.drury.id
    ips           = [local.lab.services.pihole.host]
    port_group_id = unifi_firewall_group.pihole_http.id
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

# IoT + Guest/Camera still need LAN DNS (ad blocking) via Pi-hole on Drury.
resource "unifi_firewall_zone_policy" "iot_to_pihole_dns" {
  name                      = "Allow IoT DNS to Pi-hole"
  action                    = "ALLOW"
  protocol                  = "tcp_udp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"

  source = {
    zone_id = unifi_firewall_zone.iot.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.drury.id
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

  source = {
    zone_id = unifi_firewall_zone.isolated.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.drury.id
    ips           = [local.lab.services.pihole.host]
    port_group_id = unifi_firewall_group.dns.id
  }
}

# Ensure DNS allows evaluate before any broader zone-pair defaults.
resource "unifi_firewall_zone_policy_order" "homelab_to_drury" {
  source_zone_id      = unifi_firewall_zone.homelab.id
  destination_zone_id = unifi_firewall_zone.drury.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.homelab_to_pihole_dns.id,
    unifi_firewall_zone_policy.homelab_to_pihole_http.id,
    unifi_firewall_zone_policy.homelab_to_proxmox.id,
  ]
}

resource "unifi_firewall_zone_policy_order" "iot_to_drury" {
  source_zone_id      = unifi_firewall_zone.iot.id
  destination_zone_id = unifi_firewall_zone.drury.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.iot_to_pihole_dns.id,
  ]
}

resource "unifi_firewall_zone_policy_order" "isolated_to_drury" {
  source_zone_id      = unifi_firewall_zone.isolated.id
  destination_zone_id = unifi_firewall_zone.drury.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.isolated_to_pihole_dns.id,
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
    unifi_firewall_zone_policy.iot_to_homelab_envoy.id,
  ]
}

resource "unifi_firewall_zone_policy_order" "homelab_to_isolated" {
  source_zone_id      = unifi_firewall_zone.homelab.id
  destination_zone_id = unifi_firewall_zone.isolated.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.homelab_to_isolated_block.id,
  ]
}
