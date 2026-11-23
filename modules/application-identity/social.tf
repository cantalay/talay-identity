# Google / Apple ile giriş (kimlik aracılığı). Uygulama Keycloak sayfası göstermez: istemci kc_idp_hint=<google|apple> ile
# doğrudan sağlayıcıya gider, Keycloak dönen kimliği bu realm'de bir kullanıcıya bağlar ve kodu gateway_redirect_uris'ten
# birine yollar; auth-gateway /auth/<realm>/social kodu token'a çevirir. İlk giriş akışı sorusuz: e-posta yeni ise kullanıcı
# açılır; aynı e-postalı hesap varsa YALNIZ e-postası onaylıysa ona bağlanır (talay-keycloak-providers
# idp-auto-link-verified-only), onaysızsa bağlanmaz ve tarayıcı istemcinin dönüş adresine
# error=access_denied&error_description=account_exists_unverified ile döner (Keycloak sayfası yok). Keycloak'ın
# idp-auto-link'i doğrulamadan bağlar: verify_email=false + açık kayıtta saldırgan kurbanın adresiyle parolalı kayıt olup
# kurbanın sonraki Google girişini kendi hesabına bağlatabilir (önceden hesap ele geçirme). Giriş sonrası akış
# (social-post-login, idp-unverified-account-guard) eski bağlarla da parolalı + onaysız hesaba oturum açtırmaz.
# Gateway istemcisinin erişim belirtecine identity_provider iddiası eklenir: gateway bağlama isteğinin (mode=link) gerçekten
# o sağlayıcıyla yeni yapılmış bir girişten geldiğini buradan (ve auth_time'dan) denetler. Profil gözden geçirme formu yoktur.

locals {
  social_enabled = var.social_login != null
  google_enabled = local.social_enabled && try(var.social_login.google, null) != null
  apple_enabled  = local.social_enabled && try(var.social_login.apple, null) != null
  social_guard   = local.social_enabled && var.social_unverified_guard
  social_auto_link_authenticator = {
    "verified-only" = "idp-auto-link-verified-only"
    "any"           = "idp-auto-link"
  }[var.social_link_existing_accounts]
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

# Authenticator değişince yürütme yeniden oluşturulur (destroy + create); arada geçen birkaç saniyede aynı e-postalı hesabı
# olan ilk girişler Keycloak hata sayfasında biter, yeni kullanıcılar etkilenmez.
resource "keycloak_authentication_execution" "social_auto_link" {
  count = local.social_enabled ? 1 : 0

  realm_id          = keycloak_realm.application.id
  parent_flow_alias = keycloak_authentication_flow.social_first_login[0].alias
  authenticator     = local.social_auto_link_authenticator
  requirement       = "ALTERNATIVE"
  depends_on        = [keycloak_authentication_execution.social_create_user]
}

# Her sosyal girişten sonra (bağ eskiden kurulmuş olsa da): parolalı + onaysız hesaba oturum açtırmaz.
resource "keycloak_authentication_flow" "social_post_login" {
  count = local.social_guard ? 1 : 0

  realm_id    = keycloak_realm.application.id
  alias       = "social-post-login"
  description = "Google / Apple girişi sonrası: parolalı ve e-postası onaylanmamış hesaba sosyal girişle oturum açılmaz"
  provider_id = "basic-flow"
}

resource "keycloak_authentication_execution" "social_unverified_guard" {
  count = local.social_guard ? 1 : 0

  realm_id          = keycloak_realm.application.id
  parent_flow_alias = keycloak_authentication_flow.social_post_login[0].alias
  authenticator     = "idp-unverified-account-guard"
  requirement       = "REQUIRED"
}

# Gateway'in kod değişiminden aldığı erişim belirtecinde girişin hangi sağlayıcıyla yapıldığı (Keycloak kullanıcı oturumu
# notu identity_provider; parolalı girişte yok). auth_time zaten belirteçte ("basic" kapsamı).
resource "keycloak_openid_user_session_note_protocol_mapper" "gateway_identity_provider" {
  count = local.social_enabled && var.gateway_client_enabled ? 1 : 0

  realm_id                   = keycloak_realm.application.id
  client_id                  = keycloak_openid_client.gateway[0].id
  name                       = "identity-provider"
  claim_name                 = "identity_provider"
  claim_value_type           = "String"
  session_note               = "identity_provider"
  add_to_access_token        = true
  add_to_id_token            = false
  add_to_userinfo            = false
  add_to_token_introspection = true
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
  post_broker_login_flow_alias  = local.social_guard ? keycloak_authentication_flow.social_post_login[0].alias : null
  depends_on                    = [keycloak_authentication_execution.social_unverified_guard]
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
  post_broker_login_flow_alias  = local.social_guard ? keycloak_authentication_flow.social_post_login[0].alias : null
  depends_on                    = [keycloak_authentication_execution.social_unverified_guard]
  extra_config = {
    teamId = var.social_login.apple.team_id
    keyId  = var.social_login.apple.key_id
  }
}
