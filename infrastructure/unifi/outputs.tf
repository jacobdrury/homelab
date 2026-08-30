output "homelab_network_id" {
  value = unifi_network.homelab.id
}

output "homelab_vlan_id" {
  value = unifi_network.homelab.vlan_id
}

output "homelab_subnet" {
  value = unifi_network.homelab.subnet
}
