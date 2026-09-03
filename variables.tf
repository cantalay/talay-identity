variable "kubeconfig_path" {
  type    = string
  default = "../talay-cluster/stacks/bootstrap/kubeconfig.yaml"
}

variable "keycloak_domain" {
  type = string
}

variable "postgres_host" {
  type    = string
  default = "postgresql.data.svc.cluster.local"
}

variable "postgres_database" {
  type    = string
  default = "talay"
}

variable "postgres_username" {
  type    = string
  default = "talay"
}

variable "vault_postgresql_key" {
  type    = string
  default = "platform/postgresql"
}

variable "vault_keycloak_key" {
  type    = string
  default = "platform/keycloak"
}
