locals {
  # Operator OAuth client must be tagged tag:k8s-operator in Tailscale admin
  # (Devices write + Auth Keys write). Connector nodes use tag:k8s.
  # https://tailscale.com/docs/kubernetes-operator/install-operator
  tailnet_policy = {
    tagOwners = {
      "tag:k8s-operator" = ["autogroup:admin"]
      "tag:k8s"          = ["tag:k8s-operator", "autogroup:admin"]
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
