provider "aws" {
  alias  = "account1"
  region = "eu-west-1"
  profile = "my-sso-profile" # Update with your AWS SSO profile name
}

provider "aws" {
  alias  = "account2"
  region = "eu-west-1"
  profile = "my-sso-profile" # Update with your AWS SSO profile name
}

# Dev VPC in Account1
module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  providers = { aws = aws.account1 }
  name    = "dev-vpc" # Update accordingly
  cidr    = "10.200.241.0/24" # Update with your CIDR values
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Environment = "dev" # Update accordingly
  }
}

# Prod VPC in Account2
module "prod_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  providers = { aws = aws.account2 }
  name    = "prod-vpc" # Update accordingly
  cidr    = "10.222.2.0/24" # Update with your CIDR values
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Environment = "prod" # Update accordingly
  }
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "peer_dev_to_prod" {
  provider   = aws.account1
  vpc_id     = module.dev_vpc.vpc_id
  peer_vpc_id = module.prod_vpc.vpc_id
  peer_owner_id = "ACCOUNT2_ID" # Replace with Account2's AWS Account ID
  auto_accept = false
}

# Accept Peering in Account2
resource "aws_vpc_peering_connection_accepter" "accept_peer_dev_to_prod" {
  provider   = aws.account2
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_dev_to_prod.id
  auto_accept = true
}

# Route Table Updates in Account1 (Dev VPC)
resource "aws_route" "dev_to_prod_route" {
  provider = aws.account1
  route_table_id         = "rtb-xxxx" # Replace with your route table id
  destination_cidr_block = "10.222.2.0/24" # Update with your CIDR values
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_dev_to_prod.id
}

# Route Table Updates in Account2 (Prod VPC)
resource "aws_route" "prod_to_dev_route" {
  provider = aws.account2
  route_table_id         = "rtb-xxxx" # Replace with your route table id
  destination_cidr_block = "10.200.241.0/24" # Update with your CIDR values
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_dev_to_prod.id
}

# Security Group to Allow SSH and RDP in Dev VPC
resource "aws_security_group" "dev_allow_ssh_rdp" {
  provider = aws.account1
  vpc_id   = module.dev_vpc.vpc_id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.222.2.0/24"] # Update with your CIDR values
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.222.2.0/24"] # Update with your CIDR values
  }
}

# Security Group to Allow SSH and RDP in Prod VPC
resource "aws_security_group" "prod_allow_ssh_rdp" {
  provider = aws.account2
  vpc_id   = module.prod_vpc.vpc_id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.200.241.0/24"] # Update with your CIDR values
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.200.241.0/24"] # Update with your CIDR values
  } 
}
