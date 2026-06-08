# ---------------------------------------------------------------------------------------------------------------------
# VAULT JWT AUTH METHOD FOR NOMAD WORKLOAD IDENTITY
# Required Vault-side companion to "run-nomad --enable-vault" on Nomad 1.10+, which authenticates to Vault with
# workload identity (JWT) instead of a token. Run this against your Vault cluster; it deploys no EC2 resources.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0"
    }
  }
}

provider "vault" {
  # address can also come from VAULT_ADDR; the token comes from VAULT_TOKEN.
  address = var.vault_address
}

# jwt auth method that trusts nomad's workload identity tokens. mounted at the default "jwt" path so the
# run-nomad vault block works without extra configuration.
resource "vault_jwt_auth_backend" "nomad" {
  path               = "jwt"
  description        = "jwt auth method for nomad workload identity"
  jwks_url           = var.nomad_jwks_url
  jwt_supported_algs = ["RS256", "EdDSA"]
}

# role nomad workloads log in as. bound_audiences must match the audience run-nomad emits ("vault.io").
resource "vault_jwt_auth_backend_role" "nomad_workloads" {
  backend                 = vault_jwt_auth_backend.nomad.path
  role_name               = "nomad-workloads"
  role_type               = "jwt"
  bound_audiences         = ["vault.io"]
  user_claim              = "/nomad_job_id"
  user_claim_json_pointer = true
  token_type              = "service"
  token_policies          = var.token_policies
  token_ttl               = 3600
  token_max_ttl           = 7200

  claim_mappings = {
    nomad_namespace = "nomad_namespace"
    nomad_job_id    = "nomad_job_id"
    nomad_task      = "nomad_task"
  }
}
