locals {
  auto_approver_routes = merge(
    { (var.homelab_subnet_route) = ["autogroup:member"] },
    var.enable_drury_subnet_route ? { (var.drury_subnet_route) = ["autogroup:member"] } : {},
  )

  tailnet_policy = {
    tagOwners = {
      "tag:k8s" = ["autogroup:admin"]
    }

    grants = [
      {
        src = ["*"]
        dst = ["*"]
        ip  = ["*"]
      },
    ]

    autoApprovers = {
      routes = local.auto_approver_routes
    }

    # Matches default tailnet SSH policy (check mode, own devices).
    ssh = [
      {
        action = "check"
        src    = ["autogroup:member"]
        dst    = ["autogroup:self"]
        users  = ["autogroup:nonroot", "root"]
      },
    ]
  }
}

resource "tailscale_acl" "homelab" {
  acl = jsonencode(local.tailnet_policy)

  # First apply replaces in-console policy; subsequent applies are Git-driven only.
  overwrite_existing_content = true
}
