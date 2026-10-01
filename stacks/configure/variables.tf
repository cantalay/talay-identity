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
