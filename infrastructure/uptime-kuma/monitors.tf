# HTTP monitors for public *.lab URLs (aligned with Homepage tiles).
#
# Semantics:
# - Direct app (Jellyfin, HA, Homepage, …) or transitional Envoy → legacy host:
#   max_redirects=0; 200–399 from the app (often a login 302) means the backend answered.
# - Authentik Proxy (Uptime Kuma, media *arr/qBit): an unauthenticated GET on `/`
#   only proves Envoy + Authentik (outpost start 302). Probe an Authentik
#   skip_path that reaches the app (see blueprints-uptime / blueprints-media):
#   - *arr `/api` → 401 without API key (app up)
#   - qBit `/api/v2/app/version` → 200 (app up)

locals {
  zone = local.lab.dns.zone

  monitors = {
    homepage = {
      name  = "Homepage"
      url   = "https://${local.zone}/"
      group = "Platform"
    }
    argocd = {
      name  = "Argo CD"
      url   = "https://argocd.${local.zone}/"
      group = "Platform"
    }
    authentik = {
      name  = "Authentik"
      url   = "https://auth.${local.zone}/"
      group = "Platform"
    }
    jellyfin = {
      name  = "Jellyfin"
      url   = "https://jellyfin.${local.zone}/"
      group = "Media"
    }
    qbittorrent = {
      name                  = "qBittorrent"
      url                   = "https://qbittorrent.${local.zone}/api/v2/app/version"
      group                 = "Media"
      accepted_status_codes = ["200"]
    }
    sonarr = {
      name                  = "Sonarr Anime"
      url                   = "https://sonarr.${local.zone}/api"
      group                 = "Media"
      accepted_status_codes = ["401"]
    }
    sonarr_tv = {
      name                  = "Sonarr TV"
      url                   = "https://sonarr-tv.${local.zone}/api"
      group                 = "Media"
      accepted_status_codes = ["401"]
    }
    prowlarr = {
      name                  = "Prowlarr"
      url                   = "https://prowlarr.${local.zone}/api"
      group                 = "Media"
      accepted_status_codes = ["401"]
    }
    homeassistant = {
      name  = "Home Assistant"
      url   = "https://homeassistant.${local.zone}/"
      group = "Home"
    }
    pihole = {
      name                  = "Pi-hole"
      # Authentik Proxy — probe skip_path /api (not /admin 302).
      url                   = "https://pihole.${local.zone}/api"
      group                 = "Infrastructure"
      accepted_status_codes = ["401"]
    }
    scarif = {
      name  = "scarif"
      url   = "https://scarif.${local.zone}/login"
      group = "Infrastructure"
    }
    proxmox = {
      name  = "Proxmox"
      url   = "https://proxmox.${local.zone}/"
      group = "Infrastructure"
    }
  }

  # Display order on the status page (matches Homepage sections).
  group_order = ["Platform", "Media", "Home", "Infrastructure"]

  monitor_order = {
    Platform       = ["homepage", "argocd", "authentik"]
    Media          = ["jellyfin", "qbittorrent", "sonarr", "sonarr_tv", "prowlarr"]
    Home           = ["homeassistant"]
    Infrastructure = ["pihole", "scarif", "proxmox"]
  }
}

resource "uptimekuma_monitor_http" "lab" {
  for_each = local.monitors

  name                  = each.value.name
  url                   = each.value.url
  interval              = 60
  timeout               = 15
  max_retries           = 1
  retry_interval        = 30
  active                = true
  method                = "GET"
  max_redirects         = 0
  accepted_status_codes = lookup(each.value, "accepted_status_codes", ["200-399"])
}
