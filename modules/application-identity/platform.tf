# Game Center / Play Games ile giriş (talay-keycloak-providers platform-identity; Keycloak'a eklenti olarak install stack'te
# yüklenir). Ayrı istemci <realm>-platform yalnız bu direct grant akışını kullanır: auth-gateway /auth/<realm>/platform isteğini
# buraya iletir. Kimlik kullanıcı özniteliğindedir (platform.gamecenter / platform.playgames); bağlama
# /realms/<realm>/platform-identity/link ucuyla. Play Games sırrı yapılandırmada ${vault.<anahtar>} referansıdır.

locals {
  platform_enabled = var.platform_identity != null
}

resource "keycloak_authentication_flow" "platform" {
  count = local.platform_enabled ? 1 : 0

  realm_id    = keycloak_realm.application.id
  alias       = "platform-direct-grant"
  description = "Game Center / Play Games kimliğiyle giriş (platform-identity)"
  provider_id = "basic-flow"
}

resource "keycloak_authentication_execution" "platform" {
  count = local.platform_enabled ? 1 : 0

  realm_id          = keycloak_realm.application.id
  parent_flow_alias = keycloak_authentication_flow.platform[0].alias
  authenticator     = "platform-identity"
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_execution_config" "platform" {
  count = local.platform_enabled ? 1 : 0

  realm_id     = keycloak_realm.application.id
  execution_id = keycloak_authentication_execution.platform[0].id
  # Hesap bağlama ucu yapılandırmayı bu adla arar.
  alias = "platform-identity"
  config = { for k, v in {
    gameCenterBundleIds   = join(",", var.platform_identity.game_center_bundle_ids)
    playGamesClientId     = coalesce(var.platform_identity.play_games_client_id, "")
    playGamesClientSecret = coalesce(var.platform_identity.play_games_client_secret_ref, "")
    emailDomain           = var.platform_identity.email_domain
    lastName              = var.platform_identity.last_name
    createUsers           = "true"
  } : k => v if v != "" }
}

resource "keycloak_openid_client" "platform" {
  count = local.platform_enabled ? 1 : 0

  realm_id  = keycloak_realm.application.id
  client_id = "${var.realm_name}-platform"
  name      = "${var.display_name} Platform"
  enabled   = true

  access_type                  = "PUBLIC"
  direct_access_grants_enabled = true
  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  service_accounts_enabled     = false
  full_scope_allowed           = true
  access_token_lifespan        = "300"

  authentication_flow_binding_overrides {
    direct_grant_id = keycloak_authentication_flow.platform[0].id
  }
}

resource "keycloak_openid_audience_protocol_mapper" "platform_api" {
  count = local.platform_enabled && var.api_client_enabled ? 1 : 0

  realm_id  = keycloak_realm.application.id
  client_id = keycloak_openid_client.platform[0].id
  name      = "${var.realm_name}-api-audience"

  included_client_audience = keycloak_openid_client.api[0].client_id
  add_to_access_token      = true
  add_to_id_token          = false
}
