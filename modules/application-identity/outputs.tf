output "realm" {
  value = keycloak_realm.application.realm
}

output "issuer" {
  value = "${trimsuffix(var.keycloak_url, "/")}/realms/${keycloak_realm.application.realm}"
}

output "clients" {
  value = merge(
    { for key, client in keycloak_openid_client.browser : key => client.client_id },
    { for client in keycloak_openid_client.api : "api" => client.client_id },
    { for client in keycloak_openid_client.gateway : "gateway" => client.client_id },
    { for client in keycloak_openid_client.gateway_admin : "gateway_admin" => client.client_id },
  )
}

output "roles" {
  value = sort(tolist(var.realm_roles))
}
