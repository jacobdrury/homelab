output "lab_split_dns" {
  description = "Split DNS domain and nameservers applied to the tailnet"
  value = {
    domain      = tailscale_dns_split_nameservers.lab.domain
    nameservers = tailscale_dns_split_nameservers.lab.nameservers
  }
}

output "subnet_router_routes" {
  description = "Enabled subnet routes on the interim router"
  value       = var.manage_subnet_router ? tailscale_device_subnet_routes.subnet_router[0].routes : []
}

output "k8s_operator_auth_key_id" {
  description = "Tailscale auth key ID for k8s operator (copy key from tfstate / 1Password at Phase 2)"
  value       = var.create_k8s_operator_auth_key ? tailscale_tailnet_key.k8s_operator[0].id : null
}

output "k8s_operator_auth_key" {
  description = "Preauth key for Tailscale k8s operator — store in 1Password; never commit"
  value       = var.create_k8s_operator_auth_key ? tailscale_tailnet_key.k8s_operator[0].key : null
  sensitive   = true
}
