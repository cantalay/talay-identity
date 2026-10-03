output "realm" {
  value = keycloak_realm.application.realm
}

output "issuer" {
  value = "${trimsuffix(var.keycloak_url, "/")}/realms/${keycloak_realm.application.realm}"
}

output "clients" {
  value = merge(
    { for key, client in keycloak_openid_client.browser : key => client.client_id },
    { api = keycloak_openid_client.api.client_id },
  )
}

output "roles" {
  value = sort(tolist(var.realm_roles))
}
