output "zone_id" {
  value = data.cloudflare_zone.jacobdrury.id
}

output "lab_host_fqdns" {
  value = { for k, r in cloudflare_dns_record.lab_host : k => r.name }
}

output "lab_transitional_fqdns" {
  value = { for k, r in cloudflare_dns_record.lab_transitional : k => r.name }
}

output "lab_app_fqdns" {
  value = { for k, r in cloudflare_dns_record.lab_app : k => r.name }
}

output "lab_direct_fqdns" {
  value = { for k, r in cloudflare_dns_record.lab_direct : k => r.name }
}

output "cloudflare_account_id" {
  description = "Cloudflare account ID (R2 S3 endpoint host prefix)"
  value       = data.cloudflare_zone.jacobdrury.account.id
}

output "tofu_state_bucket" {
  description = "R2 bucket for OpenTofu remote state"
  value       = cloudflare_r2_bucket.tofu_state.name
}

output "tofu_state_s3_endpoint" {
  description = "S3-compatible endpoint for OpenTofu backend \"s3\""
  value       = "https://${data.cloudflare_zone.jacobdrury.account.id}.r2.cloudflarestorage.com"
}
