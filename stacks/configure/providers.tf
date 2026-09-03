provider "keycloak" {
  url              = var.keycloak_url
  client_id        = "admin-cli"
  realm            = "master"
  keycloak_version = "26.7.3"
}
