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

variable "todogi_web_url" {
  description = "ToDoGi web adresi (gateway dönüşü /signin/callback ve PKCE yedek istemcisi)."
  type        = string
  default     = "https://todogi.net"
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
  # Kimlikler gizli değil; sırlar Keycloak dosya kasasında (Vault kv/platform/keycloak-realm-vault, alan vitafinder_<anahtar>;
  # referans realm önekisiz: $${vault.<anahtar>}). Varsayılan depoda durur ki değişkensiz bir apply sağlayıcıyı silmesin.
  default = {
    google = {
      client_id         = "469478267904-j9g23jonbbcshuqua161722m2eqhq3oa.apps.googleusercontent.com"
      client_secret_ref = "$${vault.googleclientsecret}"
    }
  }
}

variable "todogi_social_login" {
  description = "ToDoGi Google / Apple ile giriş (modül social_login; VitaPick deseni). Sırlar Keycloak kasası referansıdır; kimlikler gizli değildir. null: kapalı."
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
  # Kimlikler (Google Cloud "todogi" projesi OAuth web istemcisi; Apple Services ID, Team ID, Key ID) gelince buraya yazılır,
  # sırlar Keycloak dosya kasasına (Vault kv/platform/keycloak-realm-vault, alanlar todogi_googleclientsecret ve todogi_applep8;
  # referans realm öneksiz: $${vault.googleclientsecret}, $${vault.applep8}). Varsayılan depoda durur ki değişkensiz bir apply sağlayıcıları
  # silmesin. Örnek:
  #   google = { client_id = "<id>.apps.googleusercontent.com", client_secret_ref = "$${vault.googleclientsecret}" }
  #   apple  = { client_id = "com.cantalay.todogi.signin", team_id = "<TEAMID>", key_id = "<KEYID>", p8_ref = "$${vault.applep8}" }
  default = null
}
