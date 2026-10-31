variable "keycloak_domain" { type = string }
variable "postgres_host" { type = string }
variable "postgres_database" { type = string }
variable "postgres_username" { type = string }
variable "vault_postgresql_key" { type = string }
variable "vault_keycloak_key" { type = string }

variable "providers_image" {
  description = "Keycloak eklentileri imajı (talay-keycloak-providers; ör. ghcr.io/cantalay/talay-keycloak-providers:sha-…@sha256:…). Boş: eklenti yok."
  type        = string
  default     = ""
}

variable "vault_realm_secrets_key" {
  description = "Realm yapılandırmalarındaki $${vault.<anahtar>} sırlarının Vault yolu (alanlar <realm>_<anahtar>). Boş: Keycloak kasası kapalı."
  type        = string
  default     = ""
}
