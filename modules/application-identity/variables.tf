variable "realm_name" {
  description = "Uygulama realm adı; client id öneki olarak da kullanılır."
  type        = string
}

variable "keycloak_url" {
  type = string
}

variable "display_name" {
  type = string
}

variable "browser_clients" {
  description = "Public PKCE browser/mobil client'ları. Key, client id'yi <realm>-<key> olarak belirler."
  type = map(object({
    root_url              = string
    name                  = optional(string)
    access_token_lifespan = optional(string, "300")
    extra_redirect_uris   = optional(list(string), [])
  }))

  validation {
    condition     = alltrue([for client in values(var.browser_clients) : can(regex("^[0-9]+$", client.access_token_lifespan))])
    error_message = "access_token_lifespan saniye cinsinden tam sayı olmalı (ör. \"300\"); Keycloak \"5m\" gibi değerlerde token üretirken 500 döner."
  }
}

variable "api_client_enabled" {
  description = "Bearer-only <realm>-api client'ını oluşturur ve browser token'larına audience olarak ekler."
  type        = bool
  default     = true
}

variable "realm_roles" {
  type = set(string)

  validation {
    condition     = contains(var.realm_roles, var.default_role)
    error_message = "default_role realm_roles içinde olmalı."
  }
}

variable "default_role" {
  description = "Yeni kullanıcılara otomatik atanan realm rolü."
  type        = string
  default     = "user"
}

variable "registration_allowed" {
  description = "Self-registration."
  type        = bool
  default     = true
}

variable "gateway_client_enabled" {
  description = "auth-gateway üzerinden login için <realm>-gateway (direct grant) ve <realm>-gateway-admin (kullanıcı yönetimi) client'larını oluşturur."
  type        = bool
  default     = false
}

variable "gateway_client_id" {
  description = "Gateway (direct grant) client id; null → <realm>-gateway. Yalnız elle kurulmuş, Terraform'a import edilen eski realm'ler için (todogi: auth)."
  type        = string
  default     = null
}

variable "gateway_admin_client_id" {
  description = "Gateway admin (service account) client id; null → <realm>-gateway-admin. Import edilen eski realm'ler için (todogi: auth-gateway-admin)."
  type        = string
  default     = null
}

variable "gateway_redirect_uris" {
  description = "Gateway social login (authorization code + kc_idp_hint) için izinli redirect URI'ları. Boşsa standard flow kapalıdır."
  type        = list(string)
  default     = []
}

variable "gateway_admin_client_secret" {
  description = "<realm>-gateway-admin client secret'ı (write-only). Değer Vault'tan TF_VAR ile verilir; state'e yazılmaz."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "gateway_admin_client_secret_version" {
  description = "Secret'ı döndürmek için artırın."
  type        = string
  default     = "1"
}

variable "sso_session_idle_timeout" {
  description = "Bu süre boyunca hiç token yenilenmezse oturum düşer (kayan pencere). Uygulama admin panelleri kendi 1 saatlik hareketsizlik sınırını ayrıca uygular."
  type        = string
  default     = "168h"
}

variable "offline_access_enabled" {
  description = "Kullanıcılara offline_access rolü verilir (varsayılan roller). auth-gateway'de GATEWAY_REALMS_<REALM>_OFFLINEACCESS=true ile birlikte: mobil oturum kullanıldıkça düşmez (offline oturum hareketsizliği; SSO üst sınırı uygulanmaz)."
  type        = bool
  default     = false
}

variable "sso_session_max_lifespan" {
  description = "Düzenli kullanımda bile oturumun en fazla yaşayacağı süre; sonrası yeniden giriş."
  type        = string
  default     = "2160h"
}

variable "platform_identity" {
  description = <<-EOT
    Game Center / Play Games ile giriş (talay-keycloak-providers platform-identity eklentisi Keycloak'ta yüklü olmalı). null: kapalı.
    game_center_bundle_ids boşsa Game Center, play_games_client_id boşsa Play Games kapalıdır. play_games_client_secret_ref sırrın
    kendisi değil Keycloak kasası referansıdır ("$${vault.playgamesclientsecret}"; Vault'ta <realm>_playgamesclientsecret).
  EOT
  type = object({
    game_center_bundle_ids       = optional(list(string), [])
    play_games_client_id         = optional(string)
    play_games_client_secret_ref = optional(string)
    email_domain                 = optional(string, "platform.invalid")
    last_name                    = optional(string, "Player")
  })
  default = null
}

variable "social_login" {
  description = <<-EOT
    Google / Apple ile giriş (Keycloak kimlik aracılığı). İstemci kc_idp_hint ile Keycloak'ın yetkilendirme ucuna gider,
    dönen kodu auth-gateway /auth/<realm>/social değiştirir; gateway_redirect_uris dolu olmalı. Sırlar Keycloak kasası
    referansıdır ("$${vault.<anahtar>}"; Vault'ta <realm>_<anahtar>): Google client secret ve Apple .p8 anahtar içeriği
    (Apple eklentisi talay-keycloak-providers imajında; client_id = Services ID). null: kapalı.
  EOT
  type = object({
    google = optional(object({
      client_id         = string
      client_secret_ref = string
    }))
    apple = optional(object({
      client_id = string
      team_id   = string
      key_id    = string
      p8_ref    = string
    }))
  })
  default = null
}

variable "social_link_existing_accounts" {
  description = <<-EOT
    İlk sosyal girişte aynı e-postalı mevcut hesaba bağlama. "verified-only" (varsayılan; talay-keycloak-providers
    idp-auto-link-verified-only): yalnız e-postası onaylı, e-postası aynı ve sağlayıcının kefil olduğu hesaba bağlar; değilse
    bağlamaz, istemciye error_description=account_exists_unverified (ya da account_exists) döner. "any": Keycloak idp-auto-link,
    doğrulamadan bağlar; verify_email=false realm'de önceden hesap ele geçirmeye açıktır, yalnız eklentiler yüklenemiyorsa.
  EOT
  type        = string
  default     = "verified-only"

  validation {
    condition     = contains(["verified-only", "any"], var.social_link_existing_accounts)
    error_message = "social_link_existing_accounts \"verified-only\" ya da \"any\" olmalı."
  }
}

variable "social_unverified_guard" {
  description = "Giriş sonrası akış social-post-login (talay-keycloak-providers idp-unverified-account-guard): her sosyal girişte, bağ eskiden kurulmuş olsa da, parolalı ve e-postası onaylanmamış hesaba oturum açtırmaz (istemciye error_description=account_exists_unverified)."
  type        = bool
  default     = true
}

variable "verify_email" {
  description = "Keycloak'ın kendi e-posta doğrulama zorunluluğu: true iken doğrulanmamış kullanıcı giriş yapamaz ve Keycloak doğrulama e-postası (Keycloak sayfası) ister; realm SMTP'si (scripts/configure-realm-email.sh) gerekir. Gateway doğrulaması (auth-gateway GATEWAY_MAIL_REALMS_<REALM>_VERIFYURL) kullanan realm'lerde false kalır."
  type        = bool
  default     = false
}
