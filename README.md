# Terraform AWS Exasol Test Setup

[![Build Status](https://github.com/exasol/terraform-aws-exasol-test-setup/actions/workflows/check_terraform.yml/badge.svg)](https://github.com/exasol/terraform-aws-exasol-test-setup/actions/workflows/check_terraform.yml)
[![GitHub Latest Release][gh-release-badge]][gh-release-link]
![Terraform Version][terraform-version]

A [Terraform](https://www.terraform.io) module to create an
[Exasol](https://www.exasol.com) cluster **with default settings for testing** on [Amazon AWS](https://aws.amazon.com/).

This module is based on [terraform-aws-exasol](https://github.com/exasol/terraform-aws-exasol/). In addition, it adds the following functionality:

* Use random generated passwords
* Create a VPC, Subnet, and Security Group
* Generate an SSH key for public key authentication
* Write the credentials and keys on local disc

By that, this module allows you to quickly create an Exasol cluster for testing.

## Usage

* Create a folder for your terraform configuration. E.g. `exasolClusterSetup`
* Create a `exasolClusterSetup.tf`
  ```hcl
  provider "aws" {
    region = "eu-central-1"
  }
  module "exasol_setup" {
    source = "../../terraform-aws-test-setup"
    owner = "<YOU_EMAIL>"
    deputy = "<DEPUTY_EMAIL>"
    datanode_count = 1
    project = "<PROJECT_SHORT_TAG>"
   license = "./exasolution.lic"
  }
  ```

  The value of `owner` and `deputy` will be added to all tags as `exa:owner` and `exa:deputy`. By that you know whom this cluster belongs to.

* Create a .gitignore file in this directory

  ```gitignore
  terraform.tfstate
  .terraform
  *.lic
  *.info
  terraform.tfstate.backup
  *.tfvars
  *.lock.hcl
  generated/
  ```
* Get an Exasol license and save it as `exasolution.lic`
* Now run `terraform init` and `terraform apply`. Terraform will now create the cluster. That takes about half an hour.
* Now you can connect to the cluster. You can find the credentials in `generated/setEnv.sh`. You can simply execute `. generated/setEnv.sh` to set the credentials as environment variables.

[travis-badge]: https://travis-ci.com/exasol/terraform-aws-exasol.svg?branch=main

[travis-link]: https://travis-ci.com/exasol/terraform-aws-exasol

[gh-release-badge]: https://img.shields.io/github/tag/exasol/terraform-aws-exasol.svg?label=latest

[gh-release-link]: https://github.com/exasol/terraform-aws-exasol/releases/latest

[terraform-version]: https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg

[terraform-install]: https://www.terraform.io/downloads.html

[aws-cli]: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
