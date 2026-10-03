# auth-gateway (auth.cantalay.com/auth/<realm>/*) ile uygulama içi login:
# kullanıcı Keycloak sayfası görmez; gateway password grant ile token alır.

resource "keycloak_openid_client" "gateway" {
  count = var.gateway_client_enabled ? 1 : 0

  realm_id  = keycloak_realm.application.id
  client_id = "${var.realm_name}-gateway"
  name      = "${var.display_name} Gateway"
  enabled   = true

  access_type                  = "PUBLIC"
  direct_access_grants_enabled = true
  standard_flow_enabled        = length(var.gateway_redirect_uris) > 0
  implicit_flow_enabled        = false
  service_accounts_enabled     = false
  valid_redirect_uris          = var.gateway_redirect_uris
  full_scope_allowed           = true
  access_token_lifespan        = "5m"
}

resource "keycloak_openid_audience_protocol_mapper" "gateway_api" {
  count = var.gateway_client_enabled && var.api_client_enabled ? 1 : 0

  realm_id  = keycloak_realm.application.id
  client_id = keycloak_openid_client.gateway[0].id
  name      = "${var.realm_name}-api-audience"

  included_client_audience = keycloak_openid_client.api[0].client_id
  add_to_access_token      = true
  add_to_id_token          = false
}

resource "keycloak_openid_client" "gateway_admin" {
  count = var.gateway_client_enabled ? 1 : 0

  realm_id  = keycloak_realm.application.id
  client_id = "${var.realm_name}-gateway-admin"
  name      = "${var.display_name} Gateway Admin"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  service_accounts_enabled     = true
  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  full_scope_allowed           = false
  client_secret_wo             = var.gateway_admin_client_secret
  client_secret_wo_version     = var.gateway_admin_client_secret_version
}

data "keycloak_openid_client" "realm_management" {
  count = var.gateway_client_enabled ? 1 : 0

  realm_id  = keycloak_realm.application.id
  client_id = "realm-management"
}

resource "keycloak_openid_client_service_account_role" "gateway_admin" {
  for_each = var.gateway_client_enabled ? toset(["manage-users", "query-users", "view-users"]) : toset([])

  realm_id                = keycloak_realm.application.id
  service_account_user_id = keycloak_openid_client.gateway_admin[0].service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management[0].id
  role                    = each.key
}
