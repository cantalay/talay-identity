module "keycloak_configuration" {
  source = "../../modules/keycloak-configuration"

  keycloak_url                     = var.keycloak_url
  platform_realm                   = var.platform_realm
  platform_admin_username          = var.platform_admin_username
  argocd_url                       = var.argocd_url
  vault_url                        = var.vault_url
  vault_oidc_client_secret         = var.vault_oidc_client_secret
  vault_oidc_client_secret_version = var.vault_oidc_client_secret_version
}

module "vitafinder_identity" {
  source = "../../modules/application-identity"

  keycloak_url = var.keycloak_url
  realm_name   = "vitafinder"
  display_name = "VitaFinder"
  browser_clients = {
    storefront = {
      root_url = var.vitafinder_storefront_url
    }
    admin = {
      root_url              = var.vitafinder_admin_url
      access_token_lifespan = "180"
    }
  }
  realm_roles = [
    "admin",
    "auditor",
    "catalog_editor",
    "marketing_approver",
    "marketing_editor",
    "pricing_analyst",
    "provider_operator",
    "support",
    "user",
  ]
  gateway_client_enabled      = true
  gateway_admin_client_secret = lookup(var.gateway_admin_client_secrets, "vitafinder", null)
  # Google / Apple ile giriş: web vitrin geri dönüşü ve mobil uygulama şeması (apps/mobile app.config.ts scheme)
  gateway_redirect_uris = ["${var.vitafinder_storefront_url}/giris/geri", "vitapick://auth"]
  social_login          = var.vitafinder_social_login
}

moved {
  from = data.keycloak_realm.platform
  to   = module.keycloak_configuration.data.keycloak_realm.platform
}

moved {
  from = data.keycloak_user.platform_admin
  to   = module.keycloak_configuration.data.keycloak_user.platform_admin
}

moved {
  from = keycloak_group.platform_admins
  to   = module.keycloak_configuration.keycloak_group.platform_admins
}

moved {
  from = keycloak_user_groups.platform_admin
  to   = module.keycloak_configuration.keycloak_user_groups.platform_admin
}

moved {
  from = keycloak_openid_client.argocd
  to   = module.keycloak_configuration.keycloak_openid_client.argocd
}

moved {
  from = keycloak_openid_group_membership_protocol_mapper.argocd_groups
  to   = module.keycloak_configuration.keycloak_openid_group_membership_protocol_mapper.argocd_groups
}

moved {
  from = keycloak_openid_client.vault
  to   = module.keycloak_configuration.keycloak_openid_client.vault
}

moved {
  from = keycloak_openid_group_membership_protocol_mapper.vault_groups
  to   = module.keycloak_configuration.keycloak_openid_group_membership_protocol_mapper.vault_groups
}

# Finance Follower: kişisel kullanım; kayıt kapalı, kullanıcılar admin konsolundan açılır.
# Giriş yalnız auth-gateway (/auth/financefollower/*) üzerinden; tarayıcı (PKCE) client'ı yok.
module "financefollower_identity" {
  source = "../../modules/application-identity"

  keycloak_url                = var.keycloak_url
  realm_name                  = "financefollower"
  display_name                = "Finance Follower"
  browser_clients             = {}
  realm_roles                 = ["admin", "viewer"]
  default_role                = "viewer"
  registration_allowed        = false
  gateway_client_enabled      = true
  gateway_admin_client_secret = lookup(var.gateway_admin_client_secrets, "financefollower", null)
}

# Colony Conquest (mobil oyun): kayıt açık (oyun içi form + misafir hesabı), giriş yalnız auth-gateway
# (/auth/conquest/*); tarayıcı client'ı yok. Hesap silme API'si conquest-gateway-admin servis hesabını kullanır.
# Mobil oturum offline token'dır (auth-gateway GATEWAY_REALMS_CONQUEST_OFFLINEACCESS): kullanıldıkça düşmez, 30 gün
# hareketsizlikte düşer (Keycloak offline oturum varsayılanı); SSO üst sınırı (90 gün) uygulanmaz.
module "conquest_identity" {
  source = "../../modules/application-identity"

  keycloak_url                = var.keycloak_url
  realm_name                  = "conquest"
  display_name                = "Colony Conquest"
  browser_clients             = {}
  realm_roles                 = ["admin", "user"]
  default_role                = "user"
  registration_allowed        = true
  gateway_client_enabled      = true
  gateway_admin_client_secret = lookup(var.gateway_admin_client_secrets, "conquest", null)
  sso_session_idle_timeout    = "720h"
  offline_access_enabled      = true

  # Game Center ile giriş (conquorer docs/62 §12; talay-keycloak-providers). Kullanıcılar misafir hesapları gibi sentetik
  # e-postalı. Play Games, Play Console Games projesi ve OAuth web istemcisi hazır olunca (sır Vault'ta, kasa referansıyla) açılır.
  platform_identity = {
    game_center_bundle_ids = ["com.cantalay.colony"] # iOS paket kimliği; Android com.cantalay.colonyconquest kalır
    email_domain           = "platform.conquest.invalid"
    last_name              = "Conquest"
  }
}

# Notify (merkezi bildirim servisi) yönetim paneli: kayıt kapalı, kullanıcılar admin konsolundan açılır.
# Roller: viewer okur, operator gönderir ve cihaz/mesaj işlemleri yapar, admin yapılandırır.
# Giriş yalnız auth-gateway (/auth/notify/*) üzerinden; tarayıcı (PKCE) client'ı yok.
module "notify_identity" {
  source = "../../modules/application-identity"

  keycloak_url                = var.keycloak_url
  realm_name                  = "notify"
  display_name                = "Notify"
  browser_clients             = {}
  realm_roles                 = ["admin", "operator", "viewer"]
  default_role                = "viewer"
  registration_allowed        = false
  gateway_client_enabled      = true
  gateway_admin_client_secret = lookup(var.gateway_admin_client_secrets, "notify", null)
}

# Tela (IPTV & Social TV & Creator platformu, kod adı; tela-core/talay.yaml): kayıt açık (web/mobil kendi formu), giriş
# yalnız auth-gateway (/auth/tela/*); tarayıcı (PKCE) client'ı yok. İzinler tela-api'de rollere göre (Permissions.java);
# yönetim rolleri Keycloak admin konsolundan atanır. TV'ler kendi cihaz jetonunu kullanır (ADR-T004), Keycloak oturumu değil.
# Mobil oturum 30 gün hareketsizlikte düşer (90 gün üst sınır). Sosyal giriş dönüşü: tela://callback.
module "tela_identity" {
  source = "../../modules/application-identity"

  keycloak_url    = var.keycloak_url
  realm_name      = "tela"
  display_name    = "Tela"
  browser_clients = {}
  realm_roles = ["user", "admin", "policy-editor", "policy-approver", "legal-officer", "incident-commander", "support",
  "auditor", "catalog-editor"]
  default_role                = "user"
  registration_allowed        = true
  gateway_client_enabled      = true
  gateway_redirect_uris       = ["tela://callback"]
  gateway_admin_client_secret = lookup(var.gateway_admin_client_secrets, "tela", null)
  sso_session_idle_timeout    = "720h"
}

# ToDoGi (görev + liste + ev bütçesi; todogi-be/talay.yaml): kayıt açık (uygulamanın kendi formu), giriş auth-gateway
# üzerinden. Realm elle kurulmuştu (gateway'in varsayılan realm'i: /auth/* ve /auth/todogi/*); D19 gereği eski kullanıcılar
# korunmaz ama realm yeniden oluşturulmaz, import edilir. İstemciler mevcut adlarıyla kalır: gateway varsayılan realm ayarı
# KEYCLOAK_CLIENT_ID=auth ve yönetim istemcisi auth-gateway-admin bu adlara bağlı. Mobil oturum offline token (todogi
# gateway'in varsayılan realm'i olduğundan KEYCLOAK_OFFLINE_ACCESS=true, İP-04). E-posta onayı ve parola sıfırlama
# gateway bağlantılarıyla (Keycloak sayfası yok): verify_email false kalır, kullanıcı onaylamadan da girer (prototip A6).
# Realm SMTP'si yalnız yönetim konsolundan elle eylem için: scripts/configure-realm-email.sh. Google/Apple: todogi_social_login.
module "todogi_identity" {
  source = "../../modules/application-identity"

  keycloak_url = var.keycloak_url
  realm_name   = "todogi"
  display_name = "ToDoGi"
  browser_clients = {
    web = {
      root_url = var.todogi_web_url
    }
  }
  realm_roles                 = ["user"]
  default_role                = "user"
  registration_allowed        = true
  gateway_client_enabled      = true
  gateway_client_id           = "auth"
  gateway_admin_client_id     = "auth-gateway-admin"
  gateway_redirect_uris       = ["${var.todogi_web_url}/signin/callback", "todogi://auth"]
  gateway_admin_client_secret = lookup(var.gateway_admin_client_secrets, "todogi", null)
  sso_session_idle_timeout    = "720h"
  offline_access_enabled      = true
  verify_email                = false
  social_login                = var.todogi_social_login
}

# Elle kurulmuş realm ve istemcileri (2026-11-22 admin API'den okunan kimlikler). Apply sonrası kaldırılabilir.
import {
  to = module.todogi_identity.keycloak_realm.application
  id = "todogi"
}

import {
  to = module.todogi_identity.keycloak_openid_client.gateway[0]
  id = "todogi/c0da0ed7-c720-417a-bab7-508b9a86bda9"
}

import {
  to = module.todogi_identity.keycloak_openid_client.gateway_admin[0]
  id = "todogi/4beb54a7-dcaf-40fc-abfa-af8c49b6886c"
}

import {
  to = module.todogi_identity.keycloak_default_roles.application
  id = "todogi/9ec75fb6-4fc6-4ca3-a03d-8e415a745917"
}
