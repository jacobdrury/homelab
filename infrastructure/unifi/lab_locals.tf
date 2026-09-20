locals {
  lab = yamldecode(file("${path.module}/../lab.yaml"))

  # UniFi Network API on the Homelab gateway (UDM) — same host as gateway_cidr.
  unifi_api_url = coalesce(
    var.unifi_api_url,
    "https://${split("/", local.lab.networks.homelab.gateway_cidr)[0]}",
  )
}
