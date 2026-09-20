locals {
  # Operator OAuth client must be tagged tag:k8s-operator in Tailscale admin
  # (Devices write + Auth Keys write). Connector nodes use tag:k8s.
  # CI OAuth client (GitHub Actions) must be tagged tag:ci (Auth Keys write).
  # https://tailscale.com/docs/kubernetes-operator/install-operator
  # https://tailscale.com/docs/integrations/github/github-action
  # IPs from lab.yaml — do not hardcode Homelab addresses here.
  homelab_gateway_ip = split("/", local.lab.networks.homelab.gateway_cidr)[0]
  kubernetes_api_ip       = local.lab.networks.homelab.hosts.k8s.ip

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
        dst = [local.homelab_gateway_ip]
        ip  = ["443"]
      },
      {
        src = ["tag:ci"]
        dst = [local.kubernetes_api_ip]
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
