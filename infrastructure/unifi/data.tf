data "unifi_network" "drury" {
  name = var.drury_network_name
}

data "unifi_network" "iot" {
  name = "Drury - IoT"
}

data "unifi_network" "guest" {
  name = "Drury - Guest"
}

data "unifi_network" "camera" {
  name = "Drury - Camera"
}
