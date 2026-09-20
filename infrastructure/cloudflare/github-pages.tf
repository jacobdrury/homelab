# GitHub Pages — apex A records + www CNAME (DNS only / grey cloud).
# Import IDs captured from Cloudflare when IaC was introduced (Aug 2026).

locals {
  github_pages_apex_ips = [
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153",
  ]

  github_pages_apex_import_ids = {
    "185.199.108.153" = "96073012e7e1af9155b5bbfef6940765"
    "185.199.109.153" = "19b4fb3e34f4a26c05db0a0cfcb91a70"
    "185.199.110.153" = "27ee7ea34a55afc71aadf37a31ca35c9"
    "185.199.111.153" = "583ff29ad40d9807a42cf4246c1d02ea"
  }
}

import {
  for_each = local.github_pages_apex_import_ids
  to       = cloudflare_dns_record.github_pages_apex[each.key]
  id       = "${data.cloudflare_zone.jacobdrury.id}/${each.value}"
}

import {
  to = cloudflare_dns_record.github_pages_www
  id = "${data.cloudflare_zone.jacobdrury.id}/dc8194691bc4a16e22b890d6b49bdf2d"
}

resource "cloudflare_dns_record" "github_pages_apex" {
  for_each = toset(local.github_pages_apex_ips)

  zone_id = data.cloudflare_zone.jacobdrury.id
  name    = var.zone_name
  type    = "A"
  content = each.value
  proxied = false
  ttl     = 1
  comment = "GitHub Pages apex — managed by OpenTofu"
}

resource "cloudflare_dns_record" "github_pages_www" {
  zone_id = data.cloudflare_zone.jacobdrury.id
  name    = "www"
  type    = "CNAME"
  content = "jacobdrury.github.io"
  proxied = false
  ttl     = 1
  comment = "GitHub Pages www — managed by OpenTofu"
}
