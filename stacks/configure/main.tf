resource "keycloak_realm" "talay" {
  realm                         = "talay"
  display_name                  = "Talay"
  enabled                       = true
  terraform_deletion_protection = true

  ssl_required             = "external"
  registration_allowed     = false
  reset_password_allowed   = true
  remember_me              = true
  verify_email             = true
  login_with_email_allowed = true
  duplicate_emails_allowed = false

  access_token_lifespan                = "5m"
  access_code_lifespan                 = "1m"
  sso_session_idle_timeout             = "30m"
  sso_session_max_lifespan             = "10h"
  offline_session_idle_timeout         = "720h"
  offline_session_max_lifespan_enabled = true
  offline_session_max_lifespan         = "1440h"

  password_policy = "length(12) and upperCase(1) and lowerCase(1) and digits(1) and specialChars(1) and notUsername and passwordHistory(5)"
}

resource "keycloak_group" "platform_admins" {
  realm_id = keycloak_realm.talay.id
  name     = "talay-platform-admins"
}

resource "keycloak_group" "developers" {
  realm_id = keycloak_realm.talay.id
  name     = "talay-developers"
}

resource "keycloak_openid_client" "argocd" {
  realm_id  = keycloak_realm.talay.id
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
  realm_id   = keycloak_realm.talay.id
  client_id  = keycloak_openid_client.argocd.id
  name       = "groups"
  claim_name = "groups"
  full_path  = false
}

resource "keycloak_openid_client" "web" {
  realm_id  = keycloak_realm.talay.id
  client_id = "talay-web"
  name      = "Talay Web"
  enabled   = true

  access_type                     = "PUBLIC"
  standard_flow_enabled           = true
  implicit_flow_enabled           = false
  direct_access_grants_enabled    = false
  pkce_code_challenge_method      = "S256"
  valid_redirect_uris             = var.web_redirect_uris
  valid_post_logout_redirect_uris = var.web_redirect_uris
  web_origins                     = var.web_origins
  full_scope_allowed              = false
}

resource "keycloak_openid_client" "mobile" {
  realm_id  = keycloak_realm.talay.id
  client_id = "talay-mobile"
  name      = "Talay Mobile"
  enabled   = true

  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  pkce_code_challenge_method   = "S256"
  valid_redirect_uris          = var.mobile_redirect_uris
  full_scope_allowed           = false
}

resource "keycloak_openid_client" "api" {
  realm_id  = keycloak_realm.talay.id
  client_id = "talay-api"
  name      = "Talay API Audience"
  enabled   = true

  access_type                  = "BEARER-ONLY"
  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = false
  full_scope_allowed           = false
}

resource "keycloak_openid_audience_protocol_mapper" "web_api" {
  realm_id  = keycloak_realm.talay.id
  client_id = keycloak_openid_client.web.id
  name      = "talay-api-audience"

  included_client_audience = keycloak_openid_client.api.client_id
  add_to_id_token          = false
  add_to_access_token      = true
}

resource "keycloak_openid_audience_protocol_mapper" "mobile_api" {
  realm_id  = keycloak_realm.talay.id
  client_id = keycloak_openid_client.mobile.id
  name      = "talay-api-audience"

  included_client_audience = keycloak_openid_client.api.client_id
  add_to_id_token          = false
  add_to_access_token      = true
}
