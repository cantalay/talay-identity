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

variable "verify_email" {
  description = "Yeni kullanıcılar e-postasını doğrulamadan giriş yapamaz. Açmadan önce realm SMTP'si (scripts/configure-realm-email.sh) kurulmalı."
  type        = bool
  default     = true
}
