# Legacy firewall rules (LAN_IN). Zone-based firewall is not enabled on this controller.
# If you migrate to ZBF later, replace with unifi_firewall_zone + unifi_firewall_zone_policy.

locals {
  isolated_networks = {
    iot = {
      network = data.unifi_network.iot
      index   = 20009
    }
    guest = {
      network = data.unifi_network.guest
      index   = 20010
    }
    camera = {
      network = data.unifi_network.camera
      index   = 20011
    }
  }
}

resource "unifi_firewall_rule" "drury_to_homelab" {
  name       = "Allow Drury to Homelab"
  action     = "accept"
  ruleset    = "LAN_IN"
  rule_index = 20008
  protocol   = "all"
  enabled    = true

  src_network_id = data.unifi_network.drury.id
  dst_network_id = unifi_network.homelab.id
}

resource "unifi_firewall_rule" "homelab_to_isolated_deny" {
  for_each = local.isolated_networks

  name       = "Deny Homelab to ${each.key}"
  action     = "drop"
  ruleset    = "LAN_IN"
  rule_index = each.value.index
  protocol   = "all"
  enabled    = true

  src_network_id = unifi_network.homelab.id
  dst_network_id = each.value.network.id
}
