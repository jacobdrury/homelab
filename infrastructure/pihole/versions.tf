terraform {
  required_version = ">= 1.9.0"

  required_providers {
    pihole = {
      source  = "barryw/pihole-v6"
      version = "~> 0.3"
    }
  }
}
