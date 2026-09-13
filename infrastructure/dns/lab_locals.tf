locals {
  lab = yamldecode(file("${path.module}/../lab.yaml"))

  lab_hosts = {
    for name, host in local.lab.networks.homelab.hosts : name => host.ip
    if try(host.dns, true)
  }

  transitional_lab_hosts = try(local.lab.dns.transitional_hosts, {})

  # Storage plane: always Unraid IP (scarif.lab is Envoy HTTPS UI).
  direct_lab_hosts = merge(
    try(local.lab.dns.direct_hosts, {}),
    {
      "scarif-nfs" = local.lab.networks.homelab.hosts.scarif.ip
    },
  )

  app_lab_hosts = try(local.lab.dns.app_hosts, {})
}
