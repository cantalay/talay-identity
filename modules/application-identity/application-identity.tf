locals {
  browser_clients = {
    for key, client in var.browser_clients : key => {
      client_id             = "${var.realm_name}-${key}"
      name                  = coalesce(client.name, "${var.display_name} ${title(key)}")
      root_url              = trimsuffix(client.root_url, "/")
      access_token_lifespan = client.access_token_lifespan
      extra_redirect_uris   = client.extra_redirect_uris
    }
  }
}

resource "keycloak_realm" "application" {
  realm        = var.realm_name
  display_name = var.display_name
  enabled      = true

  ssl_required                   = "external"
  registration_allowed           = var.registration_allowed
  registration_email_as_username = false
  login_with_email_allowed       = true
  duplicate_emails_allowed       = false
  edit_username_allowed          = false
  remember_me                    = true
  reset_password_allowed         = true
  verify_email                   = false

  access_token_lifespan    = "5m"
  sso_session_idle_timeout = "30m"
  sso_session_max_lifespan = "10h"
  revoke_refresh_token     = true
  refresh_token_max_reuse  = 0

  password_policy = "length(12) and digits(1) and lowerCase(1) and upperCase(1) and specialChars(1) and passwordHistory(5) and notUsername"

  internationalization {
    supported_locales = ["tr", "en"]
    default_locale    = "tr"
  }

  security_defenses {
    brute_force_detection {
      permanent_lockout                = false
      max_login_failures               = 5
      wait_increment_seconds           = 60
      quick_login_check_milli_seconds  = 1000
      minimum_quick_login_wait_seconds = 60
      max_failure_wait_seconds         = 900
      failure_reset_time_seconds       = 43200
    }
  }
}

resource "keycloak_role" "realm" {
  for_each = var.realm_roles

  realm_id    = keycloak_realm.application.id
  name        = each.value
  description = "${var.display_name} ${each.value} role"
}

resource "keycloak_default_roles" "application" {
  realm_id      = keycloak_realm.application.id
  default_roles = [keycloak_role.realm[var.default_role].name]
}

resource "keycloak_openid_client" "browser" {
  for_each = local.browser_clients

  realm_id  = keycloak_realm.application.id
  client_id = each.value.client_id
  name      = each.value.name
  enabled   = true

  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = false
  pkce_code_challenge_method   = "S256"

  root_url                        = each.value.root_url
  base_url                        = "${each.value.root_url}/"
  valid_redirect_uris             = concat(["${each.value.root_url}/*"], each.value.extra_redirect_uris)
  valid_post_logout_redirect_uris = ["${each.value.root_url}/*"]
  web_origins                     = [each.value.root_url]
  full_scope_allowed              = true
  access_token_lifespan           = each.value.access_token_lifespan
}

resource "keycloak_openid_client" "api" {
  count = var.api_client_enabled ? 1 : 0

  realm_id  = keycloak_realm.application.id
  client_id = "${var.realm_name}-api"
  name      = "${var.display_name} API"
  enabled   = true

  access_type                  = "BEARER-ONLY"
  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = false
  full_scope_allowed           = false
}

resource "keycloak_openid_audience_protocol_mapper" "api" {
  for_each = var.api_client_enabled ? keycloak_openid_client.browser : {}

  realm_id  = keycloak_realm.application.id
  client_id = each.value.id
  name      = "${var.realm_name}-api-audience"

  included_client_audience = keycloak_openid_client.api[0].client_id
  add_to_access_token      = true
  add_to_id_token          = false
}

moved {
  from = keycloak_openid_client.api
  to   = keycloak_openid_client.api[0]
}
