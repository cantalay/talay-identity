module "keycloak_configuration" {
  source = "../../modules/keycloak-configuration"

  keycloak_url                     = var.keycloak_url
  platform_realm                   = var.platform_realm
  platform_admin_username          = var.platform_admin_username
  argocd_url                       = var.argocd_url
  vault_url                        = var.vault_url
  vault_oidc_client_secret         = var.vault_oidc_client_secret
  vault_oidc_client_secret_version = var.vault_oidc_client_secret_version
}

module "vitafinder_identity" {
  source = "../../modules/application-identity"

  keycloak_url = var.keycloak_url
  realm_name   = "vitafinder"
  display_name = "VitaFinder"
  browser_clients = {
    storefront = {
      root_url = var.vitafinder_storefront_url
    }
    admin = {
      root_url              = var.vitafinder_admin_url
      access_token_lifespan = "3m"
    }
  }
  realm_roles = [
    "admin",
    "auditor",
    "catalog_editor",
    "marketing_approver",
    "marketing_editor",
    "pricing_analyst",
    "provider_operator",
    "support",
    "user",
  ]
}

module "hello_identity" {
  source = "../../modules/application-identity"

  keycloak_url = var.keycloak_url
  realm_name   = "hello"
  display_name = "Talay Hello"
  browser_clients = {
    web = { root_url = var.hello_web_url }
  }
  realm_roles = ["user", "admin"]
}

moved {
  from = data.keycloak_realm.platform
  to   = module.keycloak_configuration.data.keycloak_realm.platform
}

moved {
  from = data.keycloak_user.platform_admin
  to   = module.keycloak_configuration.data.keycloak_user.platform_admin
}

moved {
  from = keycloak_group.platform_admins
  to   = module.keycloak_configuration.keycloak_group.platform_admins
}

moved {
  from = keycloak_user_groups.platform_admin
  to   = module.keycloak_configuration.keycloak_user_groups.platform_admin
}

moved {
  from = keycloak_openid_client.argocd
  to   = module.keycloak_configuration.keycloak_openid_client.argocd
}

moved {
  from = keycloak_openid_group_membership_protocol_mapper.argocd_groups
  to   = module.keycloak_configuration.keycloak_openid_group_membership_protocol_mapper.argocd_groups
}

moved {
  from = keycloak_openid_client.vault
  to   = module.keycloak_configuration.keycloak_openid_client.vault
}

moved {
  from = keycloak_openid_group_membership_protocol_mapper.vault_groups
  to   = module.keycloak_configuration.keycloak_openid_group_membership_protocol_mapper.vault_groups
}
