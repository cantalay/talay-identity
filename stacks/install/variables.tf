variable "kubeconfig_path" {
  type    = string
  default = "../../../talay-cluster/stacks/bootstrap/kubeconfig.yaml"
}

variable "keycloak_domain" {
  type = string
}

variable "postgres_host" {
  type    = string
  default = "postgresql.data.svc.cluster.local"
}

variable "postgres_database" {
  type    = string
  default = "talay"
}

variable "postgres_username" {
  type    = string
  default = "talay"
}

variable "vault_postgresql_key" {
  type    = string
  default = "platform/postgresql"
}

variable "vault_keycloak_key" {
  type    = string
  default = "platform/keycloak"
}

variable "providers_image" {
  description = "Keycloak eklentileri imajı (github.com/cantalay/talay-keycloak-providers, etiket + digest; herkese açık). Boş: eklenti yok."
  type        = string
  default     = "ghcr.io/cantalay/talay-keycloak-providers:sha-774a7a8@sha256:91a11f3cd9ece5781423bb55dd2879a2372673c94dac2b22201186ae0416bc25"
}

variable "vault_realm_secrets_key" {
  description = "Realm sırlarının Vault yolu (Keycloak dosya kasası; alanlar <realm>_<anahtar>). Boş: kapalı."
  type        = string
  default     = ""
}
