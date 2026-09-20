terraform {
  required_version = ">= 1.10.0"

  required_providers {
    uptimekuma = {
      source  = "breml/uptimekuma"
      version = "~> 0.4"
    }
  }
}
