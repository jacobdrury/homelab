# Zone-Based Firewall (UniFi OS 9+). Requires ZBF enabled on the UDM before apply:
# https://help.ui.com/hc/en-us/articles/28223082254743-Migrating-to-Zone-Based-Firewalls-in-UniFi
#
# Policy intent:
#   Drury → Homelab: allow all (mgmt + NFS)
#   Homelab → Drury: DNS to Pi-hole only (53/tcp+udp)
#   Homelab → IoT/Guest/Camera: deny
#   IoT/Guest/Camera → Pi-hole: DNS only
#   Homelab → Internet: rely on External zone defaults (allow)

resource "unifi_firewall_group" "dns" {
  name    = "DNS"
  type    = "port-group"
  members = ["53"]
}

# Envoy (Homelab) → legacy UIs until Phase 3 cutover.
resource "unifi_firewall_group" "arr_http" {
  name = "arr HTTP"
  type = "port-group"
  members = [
    "8096", # jellyfin
    "8085", # qbittorrent (gluetun)
    "8989", # sonarr-tv
    "8990", # sonarr-anime
    "9696", # prowlarr
  ]
}

resource "unifi_firewall_group" "pihole_http" {
  name    = "Pi-hole HTTP"
  type    = "port-group"
  members = ["80"]
}

resource "unifi_firewall_group" "homeassistant_http" {
  name    = "Home Assistant HTTP"
  type    = "port-group"
  members = ["8123"]
}

resource "unifi_firewall_group" "proxmox_https" {
  name    = "Proxmox HTTPS"
  type    = "port-group"
  members = ["8006"]
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

resource "unifi_firewall_zone" "isolated" {
  name = "Isolated"
  networks = [
    data.unifi_network.iot.id,
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

# Homelab → Drury: Pi-hole DNS + transitional Envoy proxy targets (arr / Pi-hole UI).
resource "unifi_firewall_zone_policy" "homelab_to_pihole_dns" {
  name                      = "Allow Homelab DNS to Pi-hole"
  action                    = "ALLOW"
  protocol                  = "tcp_udp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "Cluster DNS until Pi-hole is on Homelab / k8s"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.drury.id
    ips           = [local.lab.services.pihole.host]
    port_group_id = unifi_firewall_group.dns.id
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

resource "unifi_firewall_zone_policy" "homelab_to_arr_http" {
  name                      = "Allow Homelab HTTP to arr"
  action                    = "ALLOW"
  protocol                  = "tcp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "Envoy transitional *.lab → arr VM media stack"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.drury.id
    ips           = [local.lab.dns.transitional_hosts.arr]
    port_group_id = unifi_firewall_group.arr_http.id
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

# Isolated VLANs still need LAN DNS (ad blocking) via Pi-hole on Drury.
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

# Envoy → Home Assistant on IoT (before Homelab→Isolated block).
resource "unifi_firewall_zone_policy" "homelab_to_homeassistant" {
  name                      = "Allow Homelab HTTP to Home Assistant"
  action                    = "ALLOW"
  protocol                  = "tcp"
  enabled                   = true
  auto_allow_return_traffic = true
  ip_version                = "IPV4"
  description               = "Envoy transitional https://homeassistant.lab → HA OS :8123"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id       = unifi_firewall_zone.isolated.id
    ips           = [local.lab.services.homeassistant.host]
    port_group_id = unifi_firewall_group.homeassistant_http.id
  }
}

resource "unifi_firewall_zone_policy" "homelab_to_isolated_block" {
  name        = "Block Homelab to Isolated"
  action      = "BLOCK"
  protocol    = "all"
  enabled     = true
  ip_version  = "IPV4"
  description = "Homelab must not initiate to IoT / Guest / Camera"

  source = {
    zone_id = unifi_firewall_zone.homelab.id
  }

  destination = {
    zone_id = unifi_firewall_zone.isolated.id
  }
}

# Ensure DNS allows evaluate before any broader zone-pair defaults.
resource "unifi_firewall_zone_policy_order" "homelab_to_drury" {
  source_zone_id      = unifi_firewall_zone.homelab.id
  destination_zone_id = unifi_firewall_zone.drury.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.homelab_to_pihole_dns.id,
    unifi_firewall_zone_policy.homelab_to_pihole_http.id,
    unifi_firewall_zone_policy.homelab_to_arr_http.id,
    unifi_firewall_zone_policy.homelab_to_proxmox.id,
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

resource "unifi_firewall_zone_policy_order" "homelab_to_isolated" {
  source_zone_id      = unifi_firewall_zone.homelab.id
  destination_zone_id = unifi_firewall_zone.isolated.id

  before_predefined_ids = [
    unifi_firewall_zone_policy.homelab_to_homeassistant.id,
    unifi_firewall_zone_policy.homelab_to_isolated_block.id,
  ]
}
