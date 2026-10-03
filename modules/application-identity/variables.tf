variable "realm_name" {
  type = string
}

variable "keycloak_url" {
  type = string
}

variable "display_name" {
  type = string
}

variable "storefront_url" {
  type = string
}

variable "admin_url" {
  type = string
}

variable "realm_roles" {
  type = set(string)
}
