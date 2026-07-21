# ---------------------------------------------------------------------------------------------------------------------
# CONSUL JWT AUTH METHOD FOR NOMAD WORKLOAD IDENTITY
# This is the OPTIONAL Consul-side companion to "run-nomad --enable-consul-wi". It teaches Consul to trust the
# workload identity JWTs that Nomad signs, so jobs receive scoped Consul tokens instead of relying on the agent token.
# Run this against your Consul cluster (with a management token); it does NOT deploy any EC2 resources.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = ">= 2.20"
    }
  }
}

provider "consul" {
  address = var.consul_address
  token   = var.consul_token
}

# jwt auth method that trusts nomad's workload identity tokens. the bound audience must match the audience
# emitted by run-nomad (--enable-consul-wi uses "consul.io").
resource "consul_acl_auth_method" "nomad_workloads" {
  name           = "nomad-workloads"
  type           = "jwt"
  description    = "login method for nomad workloads using workload identity"
  token_locality = "local"

  config_json = jsonencode({
    JWKSURL          = var.nomad_jwks_url
    JWTSupportedAlgs = ["RS256"]
    BoundAudiences   = ["consul.io"]
    ClaimMappings = {
      nomad_namespace = "nomad_namespace"
      nomad_job_id    = "nomad_job_id"
      nomad_task      = "nomad_task"
      nomad_service   = "nomad_service"
    }
  })
}

# nomad services map to consul service identities of the same name.
# note: $${value.x} is escaped so terraform passes the literal ${value.x} through to consul.
resource "consul_acl_binding_rule" "service" {
  auth_method = consul_acl_auth_method.nomad_workloads.name
  description = "map nomad services to consul service identities"
  selector    = "\"nomad_service\" in value"
  bind_type   = "service"
  bind_name   = "$${value.nomad_service}"
}

# non-service workloads (e.g. template blocks) map to a consul role you manage separately.
resource "consul_acl_binding_rule" "task" {
  auth_method = consul_acl_auth_method.nomad_workloads.name
  description = "map nomad tasks to the nomad-tasks consul role"
  selector    = "\"nomad_service\" not in value"
  bind_type   = "role"
  bind_name   = "nomad-tasks"
}
