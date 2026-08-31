# Password via PIHOLE_PASSWORD env (moon → op). Host from lab_locals.tf → ../lab.yaml.
provider "pihole" {
  url = "http://${local.lab.services.pihole.host}"
}
