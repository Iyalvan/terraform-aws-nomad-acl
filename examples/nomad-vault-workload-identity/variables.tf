variable "vault_address" {
  description = "Address of the Vault server, e.g. https://vault.example.com:8200 (the provider also reads VAULT_ADDR)."
  type        = string
}

variable "nomad_jwks_url" {
  description = "Nomad JWKS URL that Vault uses to verify workload identity JWTs, e.g. https://nomad.example.com:4646/.well-known/jwks.json"
  type        = string
}

variable "token_policies" {
  description = "Vault policies granted to tokens issued to Nomad workloads."
  type        = list(string)
  default     = ["nomad-workloads"]
}
