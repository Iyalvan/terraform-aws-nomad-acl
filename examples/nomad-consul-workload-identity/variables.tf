variable "consul_address" {
  description = "Address of the Consul HTTP(S) API used to create the auth method, e.g. https://consul.example.com:8501"
  type        = string
}

variable "consul_token" {
  description = "A Consul ACL token allowed to manage auth methods and binding rules (e.g. the bootstrap/management token)."
  type        = string
  sensitive   = true
}

variable "nomad_jwks_url" {
  description = "Nomad JWKS URL that Consul uses to verify workload identity JWTs, e.g. https://nomad.example.com:4646/.well-known/jwks.json"
  type        = string
}
