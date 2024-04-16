# Terraform AWS Exasol Test Setup

[![Build Status](https://github.com/exasol/terraform-aws-exasol-test-setup/actions/workflows/check_terraform.yml/badge.svg)](https://github.com/exasol/terraform-aws-exasol-test-setup/actions/workflows/check_terraform.yml)
[![GitHub Latest Release][gh-release-badge]][gh-release-link]
![Terraform Version][terraform-version]

A [Terraform](https://www.terraform.io) module to create an
[Exasol](https://www.exasol.com) cluster **with default settings for testing** on [Amazon AWS](https://aws.amazon.com/).

See [Terraform module](https://registry.terraform.io/modules/exasol/exasol-test-setup/aws/latest).

This module is based on [terraform-aws-exasol](https://github.com/exasol/terraform-aws-exasol/). In addition, it adds the following functionality:

* Use random generated passwords
* Create a VPC, Subnet, and Security Group
* Generate an SSH key for public key authentication
* Write the credentials and keys on local disk

By that, this module allows you to quickly create an Exasol cluster for testing.

## Usage

* Create a folder for your terraform configuration. E.g. `exasolClusterSetup`
* Create a `exasolClusterSetup.tf`
  ```hcl
  provider "aws" {
    region = "eu-central-1"
  }
  module "exasol_setup" {
    source  = "exasol/exasol-test-setup/aws"
    version = "<LATEST VERSION>" # Replace this with the latest version of terraform-aws-exasol-test-setup.
    owner = "<YOU_EMAIL>"
    deputy = "<DEPUTY_EMAIL>"
    datanode_count = 1
    project = "<PROJECT_SHORT_TAG>"
    license = "./exasolution.lic"
  }
  ```

  The value of `owner` and `deputy` will be added to all tags as `exa:owner` and `exa:deputy`. By that you know whom this cluster belongs to.

* Create a `.gitignore` file in the current directory

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

    Additionally it might be required to specify your AWS profile selected in file `~/.aws/config`:
    ```sh
    AWS_DEFAULT_PROFILE=<NAME OF PROFILE> terraform apply
    ```
* After that you can connect to the cluster. You can find the credentials in `generated/testConfig.json`.

### Accessing the database

This module only exposes the SSH port (and currently 443 due to a limitation in terraform-aws-exasol). That means that you and attackers can't directly access the SQL interface from outside the VPC. So if you want to connect to the database from you PC you need an SSH-tunnel.

The module generates some script to set up these tunnels:

* `generated/sshTunnelAdminPage.sh`: Create an SSH tunnel for ExaOperation. You can connect to localhost:443 afterwards.
* `generated/sshTunnelSql.sh`: Create an SSH tunnel for the SQL interface. You can connect to localhost:8562 afterwards.
* `generated/sshToCluster.sh`: Just opens an SSH connection so that you can run commands in the database.

## Additional Information

- [Changelog](doc/changes/changelog.md)
- [Developer Guide](doc/developer_guide/developer_guide.md)

<!-- @formatter:off -->
[gh-release-badge]: https://img.shields.io/github/tag/exasol/terraform-aws-exasol-test-setup.svg?label=latest
[gh-release-link]: https://github.com/exasol/terraform-aws-exasol-test-setup/releases/latest
[terraform-version]: https://img.shields.io/badge/tf-%3E%3D1.5.1-blue.svg
