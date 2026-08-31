locals {
  interim_subnet_routes = concat(
    [var.homelab_subnet_route],
    var.enable_drury_subnet_route ? [var.drury_subnet_route] : [],
  )
}
