resource "random_password" "unique_id" {
  length      = 4
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

locals {
  id          = "${var.project}-${random_password.unique_id.result}"
  project_tag = replace(local.id, " ", "-")
  tags = merge(var.additional_tags, {
    "exa:owner" : var.owner,
    "exa:deputy" : var.deputy
    "exa:project" : local.id,
  })
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = merge(local.tags, {
    "Name" : "VPC for ${local.id}"
  })
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"

  tags = merge(local.tags, {
    "Name" : "Subnet for ${local.id}"
  })
}


resource "aws_default_route_table" "routing_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = merge(local.tags, {
    "Name" : "Route Table for ${local.id}"
  })
}

resource "aws_security_group" "exasol_db_security_group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  ingress {
    description = "ExaOperation from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    "Name" : "Security Group for Exasol cluster for ${local.id}"
  })
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "generated/exasol_cluster_ssh_key"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "generated/exasol_cluster_ssh_key.pub"
  file_permission = "0600"
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "${local.project_tag}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.tags, {
    "Name" : "Gateway for Exasol cluster for ${local.id}"
  })
}

resource "random_password" "exasol_sys_password" {
  length      = 20
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  # with some special chars login does not work
  special = false
}

resource "random_password" "exasol_admin_password" {
  length = 20
  numeric = true
  # with some special chars login does not work
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

module "exasol" {
  source                          = "exasol/exasol/aws"
  version                         = "1.0.2"
  cluster_name                    = "${local.project_tag}-exasol-cluster"
  database_name                   = "exadb"
  ami_image_name                  = var.exasol_image
  sys_user_password               = random_password.exasol_sys_password.result
  admin_user_password             = random_password.exasol_admin_password.result
  management_server_instance_type = var.management_server_instance_type
  datanode_instance_type          = var.datanode_instance_type
  datanode_count                  = var.datanode_count
  standbynode_count               = "0"
  public_ip                       = true

  # These values can be obtained from other modules.
  key_pair_name     = aws_key_pair.ssh_key.key_name
  subnet_id         = aws_subnet.subnet.id
  security_group_id = aws_security_group.exasol_db_security_group.id

  # Variables used in tags.
  project      = local.id
  project_name = local.id
  owner        = var.owner
  environment  = "dev"
  license      = var.license
}

resource "local_file" "test_config" {
  content         = <<EOT
{
  "dataNodeAddress": "${module.exasol.first_datanode_ip}",
  "managementNodeAddress": "${module.exasol.management_server_ip}",
  "sshPort": 22,
  "sshKey": "./exasol_cluster_ssh_key",
  "sqlUser": "sys",
  "sqlPass": "${random_password.exasol_sys_password.result}",
  "adminUser": "admin",
  "adminPass": "${random_password.exasol_admin_password.result}"
}
  EOT
  filename        = "generated/testConfig.json"
  file_permission = "0600"
}

resource "local_file" "ssh_tunnel_admin_page_script" {
  content         = <<EOT
#!/bin/bash
set -euo pipefail
scriptDir=$(dirname "$0")
EXASOL_MANAGEMENT_IP=$(jq -r .managementNodeAddress < "$scriptDir/testConfig.json")
echo "Connect now to localhost:443"
ssh -i exasol_cluster_ssh_key "ec2-user@$EXASOL_MANAGEMENT_IP" -L 443:localhost:443
  EOT
  filename        = "generated/sshTunnelAdminPage.sh"
  file_permission = "0700"
}

resource "local_file" "ssh_tunnel_sql_script" {
  content         = <<EOT
#!/bin/bash
set -euo pipefail
scriptDir=$(dirname "$0")
EXASOL_MANAGEMENT_IP=$(jq -r .managementNodeAddress < "$scriptDir/testConfig.json")
echo "Connect now to localhost:8562"
ssh -i exasol_cluster_ssh_key "ec2-user@$EXASOL_MANAGEMENT_IP" -L 8563:n11:8563
  EOT
  filename        = "generated/sshTunnelSql.sh"
  file_permission = "0700"
}

resource "local_file" "ssh_script" {
  content         = <<EOT
#!/bin/bash
set -euo pipefail
scriptDir=$(dirname "$0")
EXASOL_MANAGEMENT_IP=$(jq -r .managementNodeAddress < "$scriptDir/testConfig.json")
ssh -i exasol_cluster_ssh_key "ec2-user@$EXASOL_MANAGEMENT_IP"
  EOT
  filename        = "generated/sshToCluster.sh"
  file_permission = "0700"
}
