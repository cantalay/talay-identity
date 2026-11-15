variable "keycloak_url" {
  description = "Keycloak base URL; /auth içermez."
  type        = string
}

variable "platform_realm" {
  description = "Existing realm used for platform administrator SSO."
  type        = string
  default     = "monitoring"
}

variable "platform_admin_username" {
  description = "Existing Keycloak user granted Talay platform administrator access."
  type        = string
  default     = "alicant"
}

variable "argocd_url" {
  type = string
}

variable "vault_url" {
  type = string
}

variable "vault_oidc_client_secret" {
  description = "Vault OIDC confidential client secret. Supply from Vault through TF_VAR_vault_oidc_client_secret."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "vault_oidc_client_secret_version" {
  description = "Increment to rotate the write-only Keycloak client secret."
  type        = string
  default     = "1"
}

variable "vitafinder_storefront_url" {
  description = "Public VitaFinder storefront URL."
  type        = string
  default     = "https://vita-pick.com"
}

variable "vitafinder_admin_url" {
  description = "Public VitaFinder admin URL."
  type        = string
  default     = "https://admin.vita-pick.com"
}

variable "gateway_admin_client_secrets" {
  description = "Realm adına göre <realm>-gateway-admin secret'ları (write-only). Vault kv/apps/todogi/keycloak GATEWAY_REALMS_<REALM>_ADMINCLIENTSECRET değerlerinden TF_VAR ile verilir."
  type        = map(string)
  default     = {}
  sensitive   = true
  ephemeral   = true
}

variable "vitafinder_social_login" {
  description = "VitaPick Google / Apple ile giriş (modül social_login). Sırlar Keycloak kasası referansıdır; kimlikler gizli değildir. null: kapalı."
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
