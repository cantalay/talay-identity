# Google / Apple ile giriş (kimlik aracılığı). Uygulama Keycloak sayfası göstermez: istemci kc_idp_hint=<google|apple> ile
# doğrudan sağlayıcıya gider, Keycloak dönen kimliği bu realm'de bir kullanıcıya bağlar ve kodu gateway_redirect_uris'ten
# birine yollar; auth-gateway /auth/<realm>/social kodu token'a çevirir. İlk giriş akışı sorusuz: aynı doğrulanmış
# e-postayla hesap varsa ona bağlanır (idp-auto-link), yoksa kullanıcı açılır; profil gözden geçirme formu yoktur.

locals {
  social_enabled = var.social_login != null
  google_enabled = local.social_enabled && try(var.social_login.google, null) != null
  apple_enabled  = local.social_enabled && try(var.social_login.apple, null) != null
}

resource "keycloak_authentication_flow" "social_first_login" {
  count = local.social_enabled ? 1 : 0

  realm_id    = keycloak_realm.application.id
  alias       = "social-first-login"
  description = "Google / Apple ilk giriş: soru sormadan yeni kullanıcı ya da aynı e-postalı hesaba bağlama"
  provider_id = "basic-flow"
}

resource "keycloak_authentication_execution" "social_create_user" {
  count = local.social_enabled ? 1 : 0

  realm_id          = keycloak_realm.application.id
  parent_flow_alias = keycloak_authentication_flow.social_first_login[0].alias
  authenticator     = "idp-create-user-if-unique"
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_execution" "social_auto_link" {
  count = local.social_enabled ? 1 : 0

  realm_id          = keycloak_realm.application.id
  parent_flow_alias = keycloak_authentication_flow.social_first_login[0].alias
  authenticator     = "idp-auto-link"
  requirement       = "ALTERNATIVE"
  depends_on        = [keycloak_authentication_execution.social_create_user]
}

resource "keycloak_oidc_google_identity_provider" "google" {
  count = local.google_enabled ? 1 : 0

  realm         = keycloak_realm.application.id
  client_id     = var.social_login.google.client_id
  client_secret = var.social_login.google.client_secret_ref
  enabled       = true
  trust_email   = true
  store_token   = false
  sync_mode     = "IMPORT"
  # Keycloak'ın kendi giriş sayfası kullanılmaz; düğme uygulamadadır
  hide_on_login_page            = true
  default_scopes                = "openid email profile"
  first_broker_login_flow_alias = keycloak_authentication_flow.social_first_login[0].alias
}

# Apple: klausbetz/apple-identity-provider-keycloak (provider id "apple"); client secret alanı .p8 anahtar içeriğidir,
# eklenti istemci sırrını (6 aylık ES256 JWT) her istekte kendisi üretir. Apple e-postayı yalnız ilk girişte verir.
resource "keycloak_oidc_identity_provider" "apple" {
  count = local.apple_enabled ? 1 : 0

  realm                         = keycloak_realm.application.id
  alias                         = "apple"
  display_name                  = "Apple"
  provider_id                   = "apple"
  enabled                       = true
  client_id                     = var.social_login.apple.client_id
  client_secret                 = var.social_login.apple.p8_ref
  authorization_url             = "https://appleid.apple.com/auth/authorize"
  token_url                     = "https://appleid.apple.com/auth/token"
  trust_email                   = true
  store_token                   = false
  sync_mode                     = "IMPORT"
  hide_on_login_page            = true
  default_scopes                = "name email"
  first_broker_login_flow_alias = keycloak_authentication_flow.social_first_login[0].alias
  extra_config = {
    teamId = var.social_login.apple.team_id
    keyId  = var.social_login.apple.key_id
  }
}
