locals {
  lab = yamldecode(file("${path.module}/../lab.yaml"))

  lab_hosts = {
    for name, host in local.lab.networks.homelab.hosts : name => host.ip
    if try(host.dns, true)
  }

  transitional_lab_hosts = try(local.lab.dns.transitional_hosts, {})

  direct_lab_hosts = try(local.lab.dns.direct_hosts, {})

  app_lab_hosts = try(local.lab.dns.app_hosts, {})
}
