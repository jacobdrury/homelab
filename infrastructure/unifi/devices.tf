# Switch port overrides. filipowm/unifi replaces the device's entire port_overrides
# array on apply — every override we care about on a managed switch must be declared
# here, or UI/API overrides on other ports get wiped.

locals {
  # USW Pro Max 16 PoE · 192.168.1.197 · uplink Aggregation SFP+ 5
  pro_max_16_mac = "1c:6a:1b:67:f3:f2"
  # USW Flex 2.5G 8 PoE · 192.168.1.109 · uplink Aggregation SFP+ 3
  flex_2_5g_8_mac = "a8:9c:6c:0a:95:09"
}

# Ports pulled from UniFi API (2026-09-23): only 7 + 8 had overrides (Drury trunks).
# Port 3 → IoT for Kohler standby generator (ethernet + Energy Management App).
# Imported into state as unifi_device.flex_2_5g_8 (controller id 69556e93f786ee140fc9f00f).
resource "unifi_device" "flex_2_5g_8" {
  mac               = local.flex_2_5g_8_mac
  name              = "USW Flex 2.5G 8 PoE"
  allow_adoption    = false
  forget_on_destroy = false

  port_override {
    number                = 3
    name                  = "kohler-gen"
    forward               = "native"
    native_networkconf_id = unifi_network.lan["iot"].id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "block_all"
  }

  # Bedroom · .107
  port_override {
    number                = 7
    name                  = "Port 7"
    forward               = "all"
    native_networkconf_id = unifi_network.lan["drury"].id
    setting_preference    = "auto"
    tagged_vlan_mgmt      = "auto"
    poe_mode              = "auto"
  }

  # Flex Mini · .225
  port_override {
    number                = 8
    name                  = "Port 8"
    forward               = "all"
    native_networkconf_id = unifi_network.lan["drury"].id
    setting_preference    = "auto"
    tagged_vlan_mgmt      = "auto"
    poe_mode              = "auto"
  }
}

resource "unifi_device" "pro_max_16" {
  mac               = local.pro_max_16_mac
  name              = "USW Pro Max 16 PoE"
  allow_adoption    = false
  forget_on_destroy = false

  # Existing overrides (preserve — provider replaces the whole array)
  # IoT access ports: native + block tagged VLANs (same pattern as Homelab / kohler-gen).
  port_override {
    number                = 2
    name                  = "Port 2"
    forward               = "native"
    native_networkconf_id = unifi_network.lan["iot"].id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "block_all"
  }

  port_override {
    number                = 3
    name                  = "Port 3"
    forward               = "native"
    native_networkconf_id = unifi_network.lan["iot"].id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "block_all"
  }

  port_override {
    number                = 4
    name                  = "Port 4"
    forward               = "all"
    native_networkconf_id = unifi_network.lan["drury"].id
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
    native_networkconf_id = unifi_network.lan["drury"].id
    setting_preference    = "manual"
    tagged_vlan_mgmt      = "auto"
  }

  port_override {
    number                = 12
    name                  = "Port 12"
    forward               = "all"
    native_networkconf_id = unifi_network.lan["drury"].id
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
