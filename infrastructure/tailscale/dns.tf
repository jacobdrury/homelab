# Split DNS: off-LAN clients resolve *.lab the same as at home (Cloudflare → RFC1918).
# Prefer this resource over tailscale_dns_configuration (subdomain dedup bug in consolidated API).
resource "tailscale_dns_split_nameservers" "lab" {
  domain      = local.lab.dns.zone
  nameservers = toset(local.lab.dns.cloudflare_resolvers)
}
