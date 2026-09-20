provider "unifi" {
  api_key        = var.unifi_api_key
  api_url        = local.unifi_api_url
  allow_insecure = var.unifi_allow_insecure
  site           = var.unifi_site
}
