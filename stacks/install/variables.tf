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
  default     = "ghcr.io/cantalay/talay-keycloak-providers:sha-a6b98f3@sha256:6405652e92211105069d73d7d934eb8ef0f3a1de60d0563ff37a9ff3ffbcd865"
}

variable "vault_realm_secrets_key" {
  description = "Realm sırlarının Vault yolu (Keycloak dosya kasası; alanlar <realm>_<anahtar>). Boş: kapalı."
  type        = string
  default     = "platform/keycloak-realm-vault"
}
