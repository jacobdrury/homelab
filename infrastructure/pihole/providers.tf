# Password via PIHOLE_PASSWORD env (moon → op). Legacy LXC until retired.
provider "pihole" {
  url = "http://${coalesce(try(local.lab.services.pihole.lxc, null), local.lab.services.pihole.host)}"
}
