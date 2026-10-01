output "issuer" {
  value = module.keycloak_configuration.issuer
}

output "clients" {
  value = module.keycloak_configuration.clients
}

output "platform_admin_group" {
  value = module.keycloak_configuration.platform_admin_group
}
