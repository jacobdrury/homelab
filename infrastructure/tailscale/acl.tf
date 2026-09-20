locals {
  # Operator OAuth client must be tagged tag:k8s-operator in Tailscale admin
  # (Devices write + Auth Keys write). Connector nodes use tag:k8s.
  # CI OAuth client (GitHub Actions) must be tagged tag:ci (Auth Keys write).
  # https://tailscale.com/docs/kubernetes-operator/install-operator
  # https://tailscale.com/docs/integrations/github/github-action
  # IPs from lab.yaml — do not hardcode Homelab addresses here.
  homelab_gateway_ip = split("/", local.lab.networks.homelab.gateway_cidr)[0]

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
      # Humans: talk to other tailnet nodes (Connector, own devices, exposed Services).
      {
        src = ["autogroup:member"]
        dst = ["autogroup:member", "tag:k8s", "tag:k8s-operator"]
        ip  = ["*"]
      },
      # GitHub Actions (ephemeral tag:ci): UniFi on Homelab gateway.
      {
        src = ["tag:ci"]
        dst = [local.homelab_gateway_ip]
        ip  = ["443"]
      },
      # GitHub Actions: Uptime Kuma Socket.IO via Homelab NodePort (yavin).
      {
        src = ["tag:ci"]
        dst = [local.lab.services.uptime_kuma.api_host]
        ip  = [tostring(local.lab.services.uptime_kuma.node_port)]
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
