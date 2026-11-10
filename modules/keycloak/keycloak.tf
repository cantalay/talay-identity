resource "helm_release" "identity_secrets" {
  name      = "identity-secrets"
  namespace = "identity"
  chart     = "${path.module}/charts/identity-secrets"

  atomic  = true
  wait    = true
  timeout = 300

  values = [yamlencode({
    refreshInterval = "1h"
    postgresql      = { remoteKey = var.vault_postgresql_key }
    keycloak        = { remoteKey = var.vault_keycloak_key }
    realmVault      = { remoteKey = var.vault_realm_secrets_key }
  })]
}

locals {
  # Eklentiler (talay-keycloak-providers): init container JAR'ı providers birimine kopyalar; kc.sh start açılışta derler.
  providers_enabled = var.providers_image != ""
  realm_vault       = var.vault_realm_secrets_key != ""
  extra_init_containers = local.providers_enabled ? [{
    name            = "providers"
    image           = var.providers_image
    imagePullPolicy = "IfNotPresent"
    volumeMounts    = [{ name = "providers", mountPath = "/target" }]
    securityContext = { allowPrivilegeEscalation = false, readOnlyRootFilesystem = true, runAsNonRoot = true, capabilities = { drop = ["ALL"] } }
    resources       = { requests = { cpu = "10m", memory = "16Mi" }, limits = { memory = "32Mi" } }
  }] : []
  extra_volumes = concat(
    local.providers_enabled ? [{ name = "providers", emptyDir = {} }] : [],
    local.realm_vault ? [{ name = "realm-vault", secret = { secretName = "keycloak-realm-vault", optional = true } }] : [],
  )
  extra_volume_mounts = concat(
    local.providers_enabled ? [{ name = "providers", mountPath = "/opt/keycloak/providers" }] : [],
    local.realm_vault ? [{ name = "realm-vault", mountPath = "/opt/keycloak/vault", readOnly = true }] : [],
  )
  vault_env = local.realm_vault ? [
    { name = "KC_VAULT", value = "file" },
    { name = "KC_VAULT_DIR", value = "/opt/keycloak/vault" },
  ] : []
}

resource "helm_release" "keycloak" {
  name       = "keycloak"
  namespace  = "identity"
  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloakx"
  version    = "7.3.1"

  atomic  = true
  wait    = true
  timeout = 900

  values = [yamlencode({
    replicas          = 1
    priorityClassName = "talay-platform-critical"
    command           = ["/opt/keycloak/bin/kc.sh"]
    args              = ["start"]
    database = {
      vendor            = "postgres"
      hostname          = var.postgres_host
      port              = 5432
      database          = var.postgres_database
      username          = var.postgres_username
      existingSecret    = "keycloak-database"
      existingSecretKey = "password"
    }
    extraEnvFrom = yamlencode([{ secretRef = { name = "keycloak-bootstrap" } }])
    extraEnv = yamlencode(concat([
      { name = "KC_HOSTNAME", value = var.keycloak_domain },
      { name = "KC_HOSTNAME_STRICT", value = "true" },
      { name = "KC_PROXY_HEADERS", value = "xforwarded" },
      { name = "KC_LOG_CONSOLE_OUTPUT", value = "json" },
    ], local.vault_env))
    extraInitContainers = length(local.extra_init_containers) > 0 ? yamlencode(local.extra_init_containers) : ""
    extraVolumes        = length(local.extra_volumes) > 0 ? yamlencode(local.extra_volumes) : ""
    extraVolumeMounts   = length(local.extra_volume_mounts) > 0 ? yamlencode(local.extra_volume_mounts) : ""
    proxy = {
      enabled = true
      mode    = "forwarded"
      http    = { enabled = true }
    }
    http           = { relativePath = "/", managementRelativePath = "/" }
    health         = { enabled = true }
    metrics        = { enabled = true }
    startupProbe   = <<-EOT
      httpGet:
        path: /health
        port: http-internal
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 5
      failureThreshold: 360
      periodSeconds: 5
    EOT
    readinessProbe = <<-EOT
      httpGet:
        path: /health/ready
        port: http-internal
        scheme: HTTP
      initialDelaySeconds: 10
      timeoutSeconds: 5
      failureThreshold: 6
      periodSeconds: 10
    EOT
    serviceMonitor = { enabled = false }
    podAnnotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "9000"
      "prometheus.io/path"   = "/metrics"
    }
    ingress = {
      enabled          = true
      ingressClassName = "traefik"
      annotations      = { "cert-manager.io/cluster-issuer" = "letsencrypt" }
      rules = [{
        host  = var.keycloak_domain
        paths = [{ path = "/", pathType = "Prefix" }]
      }]
      tls = [{ secretName = "keycloak-tls", hosts = [var.keycloak_domain] }]
    }
    resources = {
      requests = { cpu = "100m", memory = "768Mi" }
      limits   = { memory = "1536Mi" }
    }
    podDisruptionBudget = {}
  })]

  depends_on = [helm_release.identity_secrets]
}
