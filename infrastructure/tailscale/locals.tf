locals {
  # Homelab route: prefer k8s Connector (prd-homelab-router) when enabled;
  # interim homelab02 keeps Drury (+ Homelab until cutover).
  interim_subnet_routes = concat(
    var.homelab_route_via_k8s ? [] : [local.lab.networks.homelab.route_cidr],
    var.enable_drury_subnet_route ? [local.lab.networks.drury.route_cidr] : [],
  )

  auto_approver_routes = merge(
    {
      (local.lab.networks.homelab.route_cidr) = concat(
        ["autogroup:member"],
        ["tag:k8s"],
      )
    },
    var.enable_drury_subnet_route ? {
      (local.lab.networks.drury.route_cidr) = ["autogroup:member"]
    } : {},
  )
}
