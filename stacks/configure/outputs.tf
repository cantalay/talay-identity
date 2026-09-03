output "issuer" {
  value = "${trimsuffix(var.keycloak_url, "/")}/realms/${keycloak_realm.talay.realm}"
}

output "clients" {
  value = {
    api    = keycloak_openid_client.api.client_id
    argocd = keycloak_openid_client.argocd.client_id
    mobile = keycloak_openid_client.mobile.client_id
    web    = keycloak_openid_client.web.client_id
  }
}
