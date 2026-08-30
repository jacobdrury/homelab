output "zone_id" {
  value = data.cloudflare_zone.jacobdrury.id
}

output "lab_host_fqdns" {
  value = { for k, r in cloudflare_dns_record.lab_host : k => r.name }
}
