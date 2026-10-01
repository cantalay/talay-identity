variable "keycloak_url" { type = string }
variable "platform_realm" { type = string }
variable "platform_admin_username" { type = string }
variable "argocd_url" { type = string }
variable "vault_url" { type = string }
variable "vault_oidc_client_secret" {
  type      = string
  sensitive = true
  ephemeral = true
}
variable "vault_oidc_client_secret_version" { type = string }
