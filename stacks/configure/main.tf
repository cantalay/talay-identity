data "keycloak_realm" "platform" {
  realm = var.platform_realm
}

data "keycloak_user" "platform_admin" {
  realm_id = data.keycloak_realm.platform.id
  username = var.platform_admin_username
}

resource "keycloak_group" "platform_admins" {
  realm_id    = data.keycloak_realm.platform.id
  name        = "talay-platform-admins"
  description = "Administrators for Talay platform services"
}

resource "keycloak_user_groups" "platform_admin" {
  realm_id   = data.keycloak_realm.platform.id
  user_id    = data.keycloak_user.platform_admin.id
  group_ids  = [keycloak_group.platform_admins.id]
  exhaustive = false
}

resource "keycloak_openid_client" "argocd" {
  realm_id  = data.keycloak_realm.platform.id
  client_id = "talay-argocd"
  name      = "Talay Argo CD"
  enabled   = true

  access_type                     = "PUBLIC"
  standard_flow_enabled           = true
  implicit_flow_enabled           = false
  direct_access_grants_enabled    = false
  pkce_code_challenge_method      = "S256"
  valid_redirect_uris             = ["${trimsuffix(var.argocd_url, "/")}/auth/callback"]
  valid_post_logout_redirect_uris = ["${trimsuffix(var.argocd_url, "/")}/"]
  web_origins                     = [trimsuffix(var.argocd_url, "/")]
  base_url                        = "${trimsuffix(var.argocd_url, "/")}/"
  full_scope_allowed              = false
}

resource "keycloak_openid_group_membership_protocol_mapper" "argocd_groups" {
  realm_id   = data.keycloak_realm.platform.id
  client_id  = keycloak_openid_client.argocd.id
  name       = "groups"
  claim_name = "groups"
  full_path  = false

  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

resource "keycloak_openid_client" "vault" {
  realm_id  = data.keycloak_realm.platform.id
  client_id = "talay-vault"
  name      = "Talay Vault"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  valid_redirect_uris = [
    "${trimsuffix(var.vault_url, "/")}/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
  valid_post_logout_redirect_uris = ["${trimsuffix(var.vault_url, "/")}/ui/"]
  web_origins                     = [trimsuffix(var.vault_url, "/")]
  base_url                        = "${trimsuffix(var.vault_url, "/")}/ui/"
  full_scope_allowed              = false

  client_secret_wo         = var.vault_oidc_client_secret
  client_secret_wo_version = var.vault_oidc_client_secret_version
}

resource "keycloak_openid_group_membership_protocol_mapper" "vault_groups" {
  realm_id   = data.keycloak_realm.platform.id
  client_id  = keycloak_openid_client.vault.id
  name       = "groups"
  claim_name = "groups"
  full_path  = false

  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}
