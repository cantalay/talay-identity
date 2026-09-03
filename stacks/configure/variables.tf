variable "keycloak_url" {
  description = "Keycloak base URL; /auth içermez."
  type        = string
}

variable "argocd_url" {
  type = string
}

variable "web_redirect_uris" {
  type = list(string)
}

variable "web_origins" {
  type = list(string)
}

variable "mobile_redirect_uris" {
  type    = list(string)
  default = ["talay://oauth/callback"]
}
