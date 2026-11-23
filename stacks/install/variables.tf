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
  default     = "ghcr.io/cantalay/talay-keycloak-providers:sha-3855bfc@sha256:bec99fed00dcc5041c4569992f275bf15651ef6088ad0baf174167d35db34bd0"
}

variable "vault_realm_secrets_key" {
  description = "Realm sırlarının Vault yolu (Keycloak dosya kasası; alanlar <realm>_<anahtar>). Boş: kapalı."
  type        = string
  default     = "platform/keycloak-realm-vault"
}
