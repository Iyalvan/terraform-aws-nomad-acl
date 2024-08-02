<!--
:type: service
:name: HashiCorp Nomad
:description: Deploy a Nomad cluster. Supports automatic bootstrapping, discovery of Consul servers, automatic recovery of failed servers.
:icon: /_docs/nomad-icon.png
:category: docker-orchestration
:cloud: aws
:tags: docker, orchestration, containers
:license: gruntwork
:built-with: terraform, bash
-->

# Nomad AWS Module

![Terraform Version](https://img.shields.io/badge/tf-%3E%3D1.0.0-blue.svg)

This repo contains a set of modules for deploying a [Nomad](https://www.nomadproject.io/) cluster on
[AWS](https://aws.amazon.com/) using [Terraform](https://www.terraform.io/). Nomad is a distributed, highly-available
data-center aware scheduler. A Nomad cluster typically includes a small number of server nodes, which are responsible
for being part of the [consensus protocol](https://www.nomadproject.io/docs/internals/consensus.html), and a larger
number of client nodes, which are used for running jobs.

Since the base repository has been archived, this fork has been enhanced with additional features including support for bootstrapping the Nomad cluster with ACL, policy, and token management, node class options to categorize the type of clients available, and more.

![Nomad architecture](https://raw.githubusercontent.com/hashicorp/terraform-aws-nomad/master/_docs/architecture.png)




## Features

* Deploy server nodes for managing jobs and client nodes running jobs
* Supports colocated clusters and separate clusters
* Least privilege security group rules for servers
* Auto scaling and Auto healing
* Support for bootstrapping the Nomad cluster with ACL, policy, and token management.
* Node class options to categorize the type of clients available.




## Learn

This repo was originally created by [Gruntwork](https://www.gruntwork.io?ref=repo_aws_nomad) and follows the same patterns as [the Gruntwork Infrastructure as Code Library](https://gruntwork.io/infrastructure-as-code-library/), a collection of reusable, battle-tested, production-ready infrastructure code. You can read [How to use the Gruntwork Infrastructure as Code Library](https://gruntwork.io/guides/foundations/how-to-use-gruntwork-infrastructure-as-code-library/) for an overview of how to use modules maintained by Gruntwork.

Since the base repository has been archived, this fork has been enhanced with additional features including support for bootstrapping the Nomad cluster with ACL, policy and token management, node class options to categorize the type of clients available, and more.

### Core concepts

* [Nomad Use Cases](https://www.nomadproject.io/intro/use-cases.html): overview of various use cases that Nomad is
  optimized for.
* [Nomad Guides](https://www.nomadproject.io/guides/index.html): official guide on how to configure and setup Nomad
  clusters as well as how to use Nomad to schedule services on to the workers.
* [Nomad Security](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/nomad-cluster#security): overview of how to secure your Nomad clusters.

### Repo organization

* [modules](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/modules): the main implementation code for this repo, broken down into multiple standalone, orthogonal submodules.
* [examples](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/examples): This folder contains working examples of how to use the submodules.
* [test](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/test): Automated tests for the modules and examples.
* [root](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master): The root folder is *an example* of how to use the [nomad-cluster module](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/modules/nomad-cluster) module to deploy a [Nomad](https://www.nomadproject.io/) cluster in [AWS](https://aws.amazon.com/). The Terraform Registry requires the root of every repo to contain Terraform code, so we've put one of the examples there. This example is great for learning and experimenting, but for production use, please use the underlying modules in the [modules folder](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules) directly.






## Deploy

### Non-production deployment (quick start for learning)

If you just want to try this repo out for experimenting and learning, check out the following resources:

* [examples folder](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/examples): The `examples` folder contains sample code optimized for learning, experimenting, and testing (but not production usage).

### Production deployment

If you want to deploy this repo in production, check out the following resources:

* [Nomad Production Setup Guide](https://www.nomadproject.io/guides/install/production/index.html):
  detailed guide covering how to setup a production deployment of Nomad.



## Manage

### Day-to-day operations

* [How to deploy Nomad and Consul in the same
  cluster](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/core-concepts.md#deploy-nomad-and-consul-in-the-same-cluster)
* [How to deploy Nomad and Consul in separate
  clusters](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/core-concepts.md#deploy-nomad-and-consul-in-separate-clusters)
* [How to connect to the Nomad cluster](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/modules/nomad-cluster/README.md#how-do-you-connect-to-the-nomad-cluster)
* [What happens if a node crashes](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/modules/nomad-cluster/README.md#what-happens-if-a-node-crashes)
* [How to connect load balancers to the ASG](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/modules/nomad-cluster/README.md#how-do-you-connect-load-balancers-to-the-auto-scaling-group-asg)

### Major changes

* [How to upgrade a Nomad cluster](https://github.com/copernicium-112/terraform-aws-nomad-acl/tree/master/modules/nomad-cluster/README.md#how-do-you-roll-out-updates)

## Who created this Module?

These modules were created by [Gruntwork](http://www.gruntwork.io/?ref=repo_aws_nomad), in partnership with HashiCorp, in 2017 and maintained through 2021. They were deprecated in 2022.

Since the base repository has been archived, this fork has been enhanced with additional features including support for bootstrapping the Nomad cluster with ACL, policy and token management, node class options to categorize the type of clients available, and more.

## License

Please see [LICENSE](https://github.com/hashicorp/terraform-aws-nomad/tree/master/LICENSE) for details on how the code in this repo is licensed.

Modifications and additional features were added by [copernicium-112](https://github.com/copernicium-112)

Copyright &copy; 2019 [Gruntwork](https://www.gruntwork.io?ref=repo_aws_nomad), Inc.
