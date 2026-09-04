terraform {
  required_version = "~> 1.16.0"

  backend "kubernetes" {}

  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.9.0"
    }
  }
}
