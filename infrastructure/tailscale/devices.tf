data "tailscale_device" "subnet_router" {
  count = var.manage_subnet_router ? 1 : 0

  hostname = local.lab.tailscale.interim_subnet_router
  wait_for = "60s"
}

resource "tailscale_device_key" "subnet_router" {
  count = var.manage_subnet_router ? 1 : 0

  device_id           = data.tailscale_device.subnet_router[0].node_id
  key_expiry_disabled = true
}

resource "tailscale_device_subnet_routes" "subnet_router" {
  count = var.manage_subnet_router ? 1 : 0

  device_id = data.tailscale_device.subnet_router[0].node_id
  routes    = local.interim_subnet_routes
}

data "tailscale_device" "k8s_subnet_router" {
  count = var.manage_k8s_subnet_router ? 1 : 0

  hostname = var.k8s_subnet_router_hostname
  wait_for = "60s"
}

resource "tailscale_device_key" "k8s_subnet_router" {
  count = var.manage_k8s_subnet_router ? 1 : 0

  device_id           = data.tailscale_device.k8s_subnet_router[0].node_id
  key_expiry_disabled = true
}

resource "tailscale_device_subnet_routes" "k8s_subnet_router" {
  count = var.manage_k8s_subnet_router ? 1 : 0

  device_id = data.tailscale_device.k8s_subnet_router[0].node_id
  routes    = [local.lab.networks.homelab.route_cidr]
}
