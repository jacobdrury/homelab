locals {
  # Operator OAuth client must be tagged tag:k8s-operator in Tailscale admin
  # (Devices write + Auth Keys write). Connector nodes use tag:k8s.
  # CI OAuth client (GitHub Actions) must be tagged tag:ci (Auth Keys write).
  # https://tailscale.com/docs/kubernetes-operator/install-operator
  # https://tailscale.com/docs/integrations/github/github-action
  tailnet_policy = {
    tagOwners = {
      "tag:k8s-operator" = ["autogroup:admin"]
      "tag:k8s"          = ["tag:k8s-operator", "autogroup:admin"]
      "tag:ci"           = ["autogroup:admin"]
    }

    grants = [
      # Humans: Homelab LAN via Connector (*.lab, UniFi gateway, kube API, …).
      {
        src = ["autogroup:member"]
        dst = [local.lab.networks.homelab.route_cidr]
        ip  = ["*"]
      },
      # Humans: talk to other tailnet nodes (Connector, own devices).
      {
        src = ["autogroup:member"]
        dst = ["autogroup:member", "tag:k8s", "tag:k8s-operator"]
        ip  = ["*"]
      },
      # GitHub Actions (ephemeral tag:ci): UniFi on Homelab gateway + kube API.
      {
        src = ["tag:ci"]
        dst = ["192.168.5.1"]
        ip  = ["443"]
      },
      {
        src = ["tag:ci"]
        dst = ["192.168.5.11"]
        ip  = ["6443"]
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
