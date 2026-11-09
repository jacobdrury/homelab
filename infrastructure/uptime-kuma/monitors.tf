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
# - qBit UI up ≠ Mullvad up (peers bind wg0). Probe the sidecar health port
#   in-cluster; Discord notifies only that monitor.

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
    grafana = {
      name                  = "Grafana"
      url                   = "https://grafana.${local.zone}/api/health"
      group                 = "Platform"
      accepted_status_codes = ["200"]
    }
    authentik = {
      name  = "Authentik"
      url   = "https://auth.${local.zone}/"
      group = "Platform"
    }
    it_tools = {
      name  = "IT-Tools"
      url   = "https://it-tools.${local.zone}/"
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
    mullvad = {
      name                  = "Mullvad (qBit)"
      # Sidecar :8081 checks wg handshake + am.i.mullvad.net via wg0.
      url                   = "http://qbittorrent.media.svc.cluster.local:8081/"
      group                 = "Media"
      accepted_status_codes = ["200"]
      notify_discord        = true
      # Health check itself curls Mullvad; give the probe a bit more room.
      timeout               = 20
      max_retries           = 2
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
    seerr = {
      name                  = "Seerr"
      # Public status endpoint (Envoy → Seerr; Jellyfin auth for UI).
      url                   = "https://seerr.${local.zone}/api/v1/status"
      group                 = "Media"
      accepted_status_codes = ["200"]
    }
    cleanuparr = {
      name                  = "Cleanuparr"
      # Authentik skip_path_regex ^/health — app liveness, not the outpost.
      url                   = "https://cleanuparr.${local.zone}/health"
      group                 = "Media"
      accepted_status_codes = ["200"]
    }
    unmanic = {
      name                  = "Unmanic"
      # Authentik skip_path_regex version/read — app liveness, not the outpost.
      url                   = "https://unmanic.${local.zone}/unmanic/api/v2/version/read"
      group                 = "Media"
      accepted_status_codes = ["200"]
    }
    homeassistant = {
      name  = "Home Assistant"
      url   = "https://homeassistant.${local.zone}/"
      group = "Home"
    }
    pihole = {
      name                  = "Pi-hole"
      # In-cluster (Authentik gates the public URL; no web password / no public API skip).
      url                   = "http://pihole.pihole.svc.cluster.local/admin/"
      group                 = "Infrastructure"
      accepted_status_codes = ["200-399"]
    }
    scarif = {
      name  = "scarif"
      url   = "https://scarif.${local.zone}/login"
      group = "Infrastructure"
    }
  }

  # Display order on the status page (matches Homepage sections).
  group_order = ["Platform", "Media", "Home", "Infrastructure"]

  monitor_order = {
    Platform       = ["homepage", "argocd", "grafana", "authentik", "it_tools"]
    Media          = ["jellyfin", "seerr", "qbittorrent", "mullvad", "sonarr", "sonarr_tv", "prowlarr", "cleanuparr", "unmanic"]
    Home           = ["homeassistant"]
    Infrastructure = ["pihole", "scarif"]
  }
}

resource "uptimekuma_monitor_http" "lab" {
  for_each = local.monitors

  name                  = each.value.name
  url                   = each.value.url
  interval              = 60
  timeout               = lookup(each.value, "timeout", 15)
  max_retries           = lookup(each.value, "max_retries", 1)
  retry_interval        = 30
  active                = true
  method                = "GET"
  max_redirects         = 0
  accepted_status_codes = lookup(each.value, "accepted_status_codes", ["200-399"])
  notification_ids = (
    lookup(each.value, "notify_discord", false)
    ? [uptimekuma_notification.discord.id]
    : []
  )
}
