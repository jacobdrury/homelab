# Public status page at https://uptime.lab.jacobdrury.com/status/default
# Provider has no import — delete a UI-created slug=default page before first apply.

resource "uptimekuma_status_page" "lab" {
  slug             = "default"
  title            = "Lab"
  description      = "Homelab service status"
  published        = true
  theme            = "auto"
  show_tags        = false
  show_powered_by  = true
  show_certificate_expiry = false

  public_group_list = [
    for i, group in local.group_order : {
      name   = group
      weight = i + 1
      monitor_list = [
        for key in local.monitor_order[group] : {
          id       = uptimekuma_monitor_http.lab[key].id
          send_url = true
          url      = lookup(local.monitors[key], "link", local.monitors[key].url)
        }
      ]
    }
  ]
}
