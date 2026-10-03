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
    access_token_lifespan = optional(string, "5m")
    extra_redirect_uris   = optional(list(string), [])
  }))
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
