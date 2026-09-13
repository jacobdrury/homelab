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
