terraform {
  required_version = "~> 1.16.0"

  backend "s3" {}

  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.9.0"
    }
  }
}
