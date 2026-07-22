# Nomad to Vault Workload Identity (auth method)

Vault-side companion to `run-nomad --enable-vault`. On Nomad 1.10+ the legacy token-based Vault
integration was removed, so Nomad authenticates to Vault with **workload identity (JWT)**. This example
provisions the Vault JWT auth method and role that trust Nomad's signed identities.

## When you need this

Only if you enable Vault integration (`run-nomad --enable-vault`). If you do not use Vault, none of this
is required and nothing changes for your cluster.

## What it creates

- a Vault JWT auth method mounted at `jwt-nomad` (the path Nomad logs in to by default) that trusts Nomad's JWKS endpoint
- a `nomad-workloads` role with `bound_audiences = ["vault.io"]` (matching what `run-nomad` emits), set as the method's `default_role`

## Usage

1. Enable Vault on the Nomad agents: `run-nomad ... --enable-vault --vault-addr https://vault...:8200`
   (this emits a `vault { default_identity { aud = ["vault.io"] } }` block; no Vault token is needed).
2. Apply this against your Vault cluster (export `VAULT_ADDR` and `VAULT_TOKEN` first):

   ```
   terraform init
   terraform apply \
     -var 'vault_address=https://vault.example.com:8200' \
     -var 'nomad_jwks_url=https://nomad.example.com:4646/.well-known/jwks.json' \
     -var 'token_policies=["my-app-policy"]'
   ```

## Notes

- The audience (`vault.io`) must match what `run-nomad` emits.
- Nomad logs in at the `jwt-nomad` auth path by default; if you mount the method elsewhere, set
  `jwt_auth_backend_path` in the Nomad `vault` block to match.
- Servers and clients no longer need a Vault token. `--vault-role` / `--vault-token` are ignored.
- This does not create any EC2 resources.
