# Nomad Run Script

This folder contains a script for configuring and running Nomad on an [AWS](https://aws.amazon.com/) server. This
script has been tested on the following operating systems:

* Ubuntu 16.04
* Ubuntu 18.04
* Amazon Linux 2

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.




## Quick start

This script assumes you installed it, plus all of its dependencies (including Nomad itself), using the [install-nomad
module](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad). The default install path is `/opt/nomad/bin`, so to start Nomad in server mode, you
run:

```
/opt/nomad/bin/run-nomad --server --num-servers 3
```

To start Nomad in client mode, you run:

```
/opt/nomad/bin/run-nomad --client
```

This will:

1. Generate a Nomad configuration file called `default.hcl` in the Nomad config dir (default: `/opt/nomad/config`).
   See [Nomad configuration](#nomad-configuration) for details on what this configuration file will contain and how
   to override it with your own configuration.

1. Generate a [systemd](https://www.freedesktop.org/wiki/Software/systemd/) configuration file called `nomad.service` in the systemd
   config dir (default: `/etc/supervisor/conf.d`) with a command that will run Nomad:  
   `nomad agent -config=/opt/nomad/config -data-dir=/opt/nomad/data`.

1. Tell systemd to load the new configuration file, thereby starting Nomad.

We recommend using the `run-nomad` command as part of [User
Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts), so that it executes
when the EC2 Instance is first booting. If you are running Consul on the same server, make sure to use this script
*after* Consul has booted. After running `run-nomad` on that initial boot, the `systemd` configuration
will automatically restart Nomad if it crashes or the EC2 instance reboots.

Note that `systemd` logs to its own journal by default.  To view the Nomad logs, run `journalctl -u nomad.service`.  To change
the log output location, you can specify the `StandardOutput` and `StandardError` options by using the `--systemd-stdout` and `--systemd-stderr`
options.  See the [`systemd.exec` man pages](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#StandardOutput=) for available
options, but note that the `file:path` option requires [systemd version >= 236](https://stackoverflow.com/a/48052152), which is not provided 
in the base Ubuntu 16.04 and Amazon Linux 2 images.

See the [nomad-consul-colocated-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/MAIN.md) and
[nomad-consul-separate-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-separate-cluster example) for fully-working sample code.




## Command line Arguments

The `run-nomad` script accepts the following arguments:

* `server` (optional): If set, run in server mode. At least one of `--server` or `--client` must be set.
* `client` (optional): If set, run in client mode. At least one of `--server` or `--client` must be set.
* `num-servers` (optional): The number of servers to expect in the Nomad cluster. Required if `--server` is set.
* `config-dir` (optional): The path to the Nomad config folder. Default is to take the absolute path of `../config`,
  relative to the `run-nomad` script itself.
* `data-dir` (optional): The path to the Nomad config folder. Default is to take the absolute path of `../data`,
  relative to the `run-nomad` script itself.
* `systemd-stdout` (optional): The StandardOutput option of the systemd unit. If not specified, it will use systemd's default (journal).
* `systemd-stderr` (optional): The StandardError option of the systemd unit. If not specified, it will use systemd's default (inherit).
* `user` (optional): The user to run Nomad as. Default is to use the owner of `config-dir`.
* `use-sudo` (optional): Nomad clients make use of operating system primitives for resource isolation that require
  elevated (root) permissions (see [the
  docs](https://www.nomadproject.io/intro/getting-started/running.html) for more info). If you set this flag, Nomad
  will run with root-level privileges. If you don't, it'll still work, but certain task drivers will not be available.
  By default, this flag is enabled if `--client` is set and disabled if `--server` is set (server nodes don't need
  root-level privileges).
* `skip-nomad-config`: If this flag is set, don't generate a Nomad configuration file. This is useful if you have
  a custom configuration file and don't want to use any of of the default settings from `run-nomad`.
* `node-pool` (optional): Assign this client to the named Nomad [node pool](https://developer.hashicorp.com/nomad/docs/architecture/cluster/node-pools)
  (Nomad 1.6+). Valid only with `--client`; passing it with `--server` is an error. Omit it (the default) and the
  client joins the built-in `default` pool, exactly as before — so this is fully opt-in. See [Node pools](#node-pools) below.

Example:

```
/opt/nomad/bin/run-nomad --server --num-servers 3
```

## Node pools

[Node pools](https://developer.hashicorp.com/nomad/docs/architecture/cluster/node-pools) (Nomad 1.6+) group
client nodes so jobs can target a subset of the fleet (e.g. `batch` vs `service`, GPU nodes). To place a
client in a pool, run it with `--node-pool <name>`:

```
/opt/nomad/bin/run-nomad --client --node-pool batch
```

A job then targets it with a top-level `node_pool = "batch"`. This is optional and opt-in: without the flag a
client joins the built-in `default` pool and behavior is unchanged. Adopting it is just the one flag on the
clients you want segmented — no extra cluster setup in the common case, because:

- **Pools auto-create.** When a client registers referencing a pool that doesn't exist yet, Nomad creates it
  (with default settings) automatically — you do **not** have to pre-create it. **Caveat (multi-region):** this
  only happens in the *authoritative* region. In a federated cluster, a client in a non-authoritative region
  stays `initializing` until the pool is created in the authoritative region and replicated. If you run
  multi-region, create the pool first (see below).
- `default` and `all` are **reserved** names (`all` is a pseudo-pool meaning every node); don't use them as a
  custom pool.

If you want a pool with a description/metadata, or (Nomad **Enterprise**) a per-pool scheduler config such as a
distinct scheduling algorithm or memory oversubscription, define it declaratively with the Terraform `nomad`
provider's [`nomad_node_pool`](https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/resources/node_pool)
resource. That is control-plane configuration and lives outside this AMI/module, alongside your other Nomad
provider resources.


## Workload identity

[Workload identity](https://developer.hashicorp.com/nomad/docs/concepts/workload-identity) (WI) lets Nomad
issue short-lived JWTs to running workloads so they can authenticate to Consul and Vault without long-lived
static tokens. `run-nomad` supports three independent integration modes — each is opt-in and can be used
separately or together.


### Agent token (all versions)

The Nomad agent needs a Consul token for its own operations (cluster discovery, service registration). This
token is read from SSM at boot via `--consul-cluster-tag-value` and written into the agent's `consul { token }`
block. It is **not** affected by workload identity and is required regardless of whether WI is enabled.


### Vault WI (`--enable-vault`)

Nomad 1.10 removed token-based Vault authentication — if you use Vault, WI is mandatory. When `--enable-vault`
is set, `run-nomad` emits:

```hcl
vault {
  enabled = true
  address = "<--vault-addr>"
  default_identity {
    aud = ["vault.io"]
  }
}
```

Servers and clients authenticate to Vault via JWT only; no Vault token is stored on any agent.

The Vault side requires a JWT auth method (mounted at `jwt-nomad` by default) that trusts Nomad's JWKS
endpoint, plus a role and policies for your workloads. See
[`examples/nomad-vault-workload-identity`](../../examples/nomad-vault-workload-identity) for the Terraform
to provision this.


### Consul WI (`--enable-consul-wi`, opt-in)

Token-based Consul integration works on all supported versions — `--enable-consul-wi` is an optional upgrade
for least-privilege. When set, `run-nomad` adds `service_identity` and `task_identity` defaults (audience
`consul.io`, auth method `nomad-workloads`) to the agent's `consul {}` block, so workloads receive
per-task scoped Consul tokens via JWT instead of sharing the agent token.

Version-dependent behavior:

* **Nomad 1.10.0–2.0.3:** the workload fallback to the agent's Consul token was removed. Workloads that touch
  Consul (service registration, KV templates) **require** WI on these versions — without it they fail. Enable
  `--enable-consul-wi` and provision the auth method before running Consul-aware jobs.
* **Nomad 2.0.4+:** the fallback was [restored](https://github.com/hashicorp/nomad/issues/28199). Workloads
  without WI configured fall back to the agent's Consul token automatically. Consul WI is optional but still
  recommended for least privilege.
* **Important:** once `--enable-consul-wi` is enabled, workloads rely on WI — there is no fallback to the
  agent token even on 2.0.4+. The Consul JWT auth method **must** be in place before you enable this flag on
  the agents.

See [`examples/nomad-consul-workload-identity`](../../examples/nomad-consul-workload-identity) for the
Consul-side auth method, binding rules, and role Terraform.


## Nomad configuration

`run-nomad` generates a configuration file for Nomad called `default.hcl` that tries to figure out reasonable
defaults for a Nomad cluster in AWS. Check out the [Nomad Configuration Files
documentation](https://www.nomadproject.io/docs/agent/configuration/index.html) for what configuration settings are
available.


### Default configuration

`run-nomad` sets the following configuration values by default:

* [advertise](https://www.nomadproject.io/docs/agent/configuration/index.html#advertise): All the advertise addresses
  are set to the Instance's private IP address, as fetched from  
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* [bind_addr](https://www.nomadproject.io/docs/agent/configuration/index.html#bind_addr): Set to 0.0.0.0.

* [client](https://www.nomadproject.io/docs/agent/configuration/client.html): This config is only set of `--client` is
  set.

    * [enabled](https://www.nomadproject.io/docs/agent/configuration/client.html#enabled): `true`.

* [consul](https://www.nomadproject.io/docs/agent/configuration/consul.html): By default, set the Consul address to
  `127.0.0.1:8500`, with the assumption that the Consul agent is running on the same server.

* [datacenter](https://www.nomadproject.io/docs/agent/configuration/index.html#datacenter): Set to the current
  availability zone, as fetched from
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* [name](https://www.nomadproject.io/docs/agent/configuration/index.html#name): Set to the instance id, as fetched from
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).     

* [region](https://www.nomadproject.io/docs/agent/configuration/index.html#region): Set to the current AWS region, as
  fetched from [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* [server](https://www.nomadproject.io/docs/agent/configuration/server.html): This config is only set if `--server` is
  set.

    * [enabled](https://www.nomadproject.io/docs/agent/configuration/server.html#enabled): `true`.
    * [bootstrap_expect](https://www.nomadproject.io/docs/agent/configuration/server.html#bootstrap_expect): Set to the
      `--num-servers` parameter.


### Overriding the configuration

To override the default configuration, simply put your own configuration file in the Nomad config folder (default:
`/opt/nomad/config`), but with a name that comes later in the alphabet than `default.hcl` (e.g.
`my-custom-config.hcl`). Nomad will load all the `.hcl` configuration files in the config dir and
[merge them together in alphabetical
order](https://www.nomadproject.io/docs/agent/configuration/index.html#load-order-and-merging), so that settings in
files that come later in the alphabet will override the earlier ones.

For example, to override the default `name` setting, you could create a file called `tags.hcl` with the
contents:

```hcl
name = "my-custom-name"
```

If you want to override *all* the default settings, you can tell `run-nomad` not to generate a default config file
at all using the `--skip-nomad-config` flag:

```
/opt/nomad/bin/run-nomad --server --num-servers 3 --skip-nomad-config
```




## How do you handle encryption?

Nomad can encrypt all of its network traffic (see the [encryption docs for
details](https://www.nomadproject.io/docs/agent/encryption.html)), but by default, encryption is not enabled in this
Module. To enable encryption, you need to do the following:

1. [Gossip encryption: provide an encryption key](#gossip-encryption-provide-an-encryption-key)
1. [RPC encryption: provide TLS certificates](#rpc-encryption-provide-tls-certificates)
1. [Consul encryption](#consul-encryption)


### Gossip encryption: provide an encryption key

To enable Gossip encryption, you need to provide a 16-byte, Base64-encoded encryption key, which you can generate using
the [nomad keygen command](https://www.nomadproject.io/docs/commands/keygen.html). You can put the key in a Nomad
configuration file (e.g. `encryption.hcl`) in the Nomad config dir (default location: `/opt/nomad/config`):

```hcl
server {
  encrypt = "cg8StVXbQJ0gPvMd9o7yrg=="
}
```


### RPC encryption: provide TLS certificates

To enable RPC encryption, you need to provide the paths to the CA and signing keys ([here is a tutorial on generating
these keys](http://russellsimpkins.blogspot.com/2015/10/consul-adding-tls-using-self-signed.html)). You can specify
these paths in a Nomad configuration file (e.g. `encryption.hcl`) in the Nomad config dir (default location:
`/opt/nomad/config`):

```hcl
tls {
  # Enable encryption on incoming HTTP and RPC endpoints
  http = true
  rpc  = true

  # Verify server hostname for outgoing TLS connections
  verify_server_hostname = true

  # Specify the CA and signing key paths
  ca_file   = "/opt/nomad/tls/certs/ca-bundle.crt",
  cert_file = "/opt/nomad/tls/certs/my.crt",
  key_file  = "/opt/nomad/tls/private/my.key"
}
```


### Consul encryption

Note that Nomad relies on Consul, and enabling encryption for Consul requires a separate process. Check out the
[official Consul encryption docs](https://www.consul.io/docs/agent/encryption.html) and the Consul AWS Module
[How do you handle encryption
docs](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/run-consul#how-do-you-handle-encryption)
for more info.
