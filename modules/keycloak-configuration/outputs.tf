output "issuer" { value = "${trimsuffix(var.keycloak_url, "/")}/realms/${data.keycloak_realm.platform.realm}" }
output "clients" {
  value = {
    argocd = keycloak_openid_client.argocd.client_id
    vault  = keycloak_openid_client.vault.client_id
  }
}
output "platform_admin_group" { value = keycloak_group.platform_admins.name }
