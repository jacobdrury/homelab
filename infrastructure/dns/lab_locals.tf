locals {
  lab = yamldecode(file("${path.module}/../lab.yaml"))

  lab_hosts = {
    for name, host in local.lab.networks.homelab.hosts : name => host.ip
  }
}
