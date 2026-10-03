output "issuer" {
  value = module.keycloak_configuration.issuer
}

output "clients" {
  value = module.keycloak_configuration.clients
}

output "platform_admin_group" {
  value = module.keycloak_configuration.platform_admin_group
}

output "vitafinder_identity" {
  value = {
    realm   = module.vitafinder_identity.realm
    clients = module.vitafinder_identity.clients
    roles   = module.vitafinder_identity.roles
  }
}
