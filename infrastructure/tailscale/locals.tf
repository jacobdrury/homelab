locals {
  interim_subnet_routes = concat(
    [local.lab.networks.homelab.route_cidr],
    var.enable_drury_subnet_route ? [local.lab.networks.drury.route_cidr] : [],
  )
}
