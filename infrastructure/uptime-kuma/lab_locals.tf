locals {
  lab = yamldecode(file("${path.module}/../lab.yaml"))
}
