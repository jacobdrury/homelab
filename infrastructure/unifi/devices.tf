# Switch port overrides. filipowm/unifi replaces the device's entire port_overrides
# array on apply — every override we care about on a managed switch must be declared
# here, or UI/API overrides on other ports get wiped.

locals {
  # USW Pro Max 16 PoE · 192.168.1.197 · uplink Aggregation SFP+ 5
  pro_max_16_mac = "1c:6a:1b:67:f3:f2"
}

resource "unifi_device" "pro_max_16" {
  mac               = local.pro_max_16_mac
  name              = "USW Pro Max 16 PoE"
  allow_adoption    = false
  forget_on_destroy = false

  # Existing overrides (preserve — provider replaces the whole array)
  port_override {
    number                = 2
    name                  = "Port 2"
    forward               = "customize"
    native_networkconf_id = data.unifi_network.iot.id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "auto"
  }

  port_override {
    number                = 3
    name                  = "Port 3"
    forward               = "customize"
    native_networkconf_id = data.unifi_network.iot.id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "auto"
  }

  port_override {
    number                = 4
    name                  = "Port 4"
    forward               = "all"
    native_networkconf_id = data.unifi_network.drury.id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "auto"
  }

  # yavin onboard 1G — Homelab VLAN 5 (fallback if USB 2.5G dies)
  port_override {
    number                = 5
    name                  = "yavin-1g"
    forward               = "native"
    native_networkconf_id = unifi_network.homelab.id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "block_all"
  }

  port_override {
    number                = 11
    name                  = "Port 11"
    forward               = "all"
    native_networkconf_id = data.unifi_network.drury.id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "auto"
  }

  port_override {
    number                = 12
    name                  = "Port 12"
    forward               = "all"
    native_networkconf_id = data.unifi_network.drury.id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "auto"
  }

  # yavin USB 2.5G (currently in Port 13) → Homelab VLAN 5 (access)
  port_override {
    number                = 13
    name                  = "yavin"
    forward               = "native"
    native_networkconf_id = unifi_network.homelab.id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "block_all"
  }
}
