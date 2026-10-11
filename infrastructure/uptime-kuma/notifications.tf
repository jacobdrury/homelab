# Discord alerts (same webhook channel as Sonarr). Homelab item:
#   prd Discord Lab Alerts → password = webhook URL
resource "uptimekuma_notification" "discord" {
  name      = "Discord"
  type      = "discord"
  is_active = true
  # Attach explicitly on monitors that should page; do not spam every probe.
  is_default     = false
  apply_existing = false
  config = jsonencode({
    discordWebhookUrl   = var.discord_webhook_url
    discordUsername     = "Uptime Kuma"
    discordChannelType  = "channel"
    discordMessageFormat = "normal"
  })
}
