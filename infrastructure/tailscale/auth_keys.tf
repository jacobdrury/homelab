resource "tailscale_tailnet_key" "k8s_operator" {
  count = var.create_k8s_operator_auth_key ? 1 : 0

  description         = "prd-k8s-operator"
  reusable          = true
  ephemeral         = false
  preauthorized     = true
  expiry            = 7776000 # 90 days
  recreate_if_invalid = "always"
  tags              = ["tag:k8s"]
}
