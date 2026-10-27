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

output "financefollower_identity" {
  value = {
    realm   = module.financefollower_identity.realm
    clients = module.financefollower_identity.clients
    roles   = module.financefollower_identity.roles
  }
}

output "conquest_identity" {
  value = {
    realm   = module.conquest_identity.realm
    clients = module.conquest_identity.clients
    roles   = module.conquest_identity.roles
  }
}

output "notify_identity" {
  value = {
    realm   = module.notify_identity.realm
    clients = module.notify_identity.clients
    roles   = module.notify_identity.roles
  }
}

output "tela_identity" {
  value = {
    realm   = module.tela_identity.realm
    clients = module.tela_identity.clients
    roles   = module.tela_identity.roles
  }
}
