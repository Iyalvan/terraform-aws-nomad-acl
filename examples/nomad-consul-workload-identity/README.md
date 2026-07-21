# Nomad to Consul Workload Identity (auth method)

This is an **optional** example that provisions the Consul-side configuration which makes Nomad
workload identity (WI) work for Consul. It pairs with `run-nomad --enable-consul-wi`.

## When you need this

Only if you want jobs to obtain scoped Consul tokens via JWT instead of using the Nomad agent's Consul
token. **Token-based Consul integration keeps working without any of this** — WI is purely opt-in.

## What it creates

- a `jwt` Consul ACL auth method (`nomad-workloads`) that trusts Nomad's JWKS endpoint
- binding rules mapping Nomad services to Consul service identities, and other workloads to a role

## Usage

1. Enable WI on the Nomad agents: `run-nomad ... --enable-consul-wi` (this bakes `service_identity` and
   `task_identity` defaults with audience `consul.io`).
2. Apply this against your Consul cluster with a management token:

   ```
   terraform init
   terraform apply \
     -var 'consul_address=https://consul.example.com:8501' \
     -var 'consul_token=<management-token>' \
     -var 'nomad_jwks_url=https://nomad.example.com:4646/.well-known/jwks.json'
   ```
3. Separately, create the `nomad-tasks` Consul role with whatever policies your `template` blocks need.

## Notes

- The audience (`consul.io`) must match what `run-nomad` emits.
- `nomad_jwks_url` must be reachable from **all** Consul servers and should resolve to multiple Nomad
  agents to avoid a single point of failure. Both Nomad servers and clients serve the JWKS endpoint.
- Do **not** set `max_token_ttl` on the auth method — Nomad cannot recreate deleted Consul tokens, so
  a TTL cap can cause workloads to lose access with no recovery path.
- If Nomad uses mTLS, set `tls.verify_https_client = false` in Nomad's TLS config so that Consul can
  reach the JWKS endpoint without a client certificate.
- On Nomad 2.0.4+, workloads without WI configured (no `service_identity`/`task_identity` in the agent)
  fall back to the agent's Consul token. Once WI **is** configured via `--enable-consul-wi`, workloads
  rely on it — ensure this auth method is in place before enabling WI on agents.
- This does not create any EC2 resources.
