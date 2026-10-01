module "keycloak" {
  source = "../../modules/keycloak"

  keycloak_domain      = var.keycloak_domain
  postgres_host        = var.postgres_host
  postgres_database    = var.postgres_database
  postgres_username    = var.postgres_username
  vault_postgresql_key = var.vault_postgresql_key
  vault_keycloak_key   = var.vault_keycloak_key
}

moved {
  from = helm_release.identity_secrets
  to   = module.keycloak.helm_release.identity_secrets
}

moved {
  from = helm_release.keycloak
  to   = module.keycloak.helm_release.keycloak
}
