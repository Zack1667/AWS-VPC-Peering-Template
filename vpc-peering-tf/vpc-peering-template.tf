provider "aws" {
  alias   = "account1"
  region  = "eu-west-1"
  profile = "sso-profile" # Replace with correct AWS SSO profile
}

provider "aws" {
  alias   = "account2"
  region  = "eu-west-1"
  profile = "sso-profile" # Replace with correct AWS SSO profile
}

# Variables - Update with actual values
variable "dev_vpc_id" {
  default = "vpc-xxxxxxxxxxxxxxxxx" # Replace with the Dev VPC ID
}

variable "prod_vpc_id" {
  default = "vpc-yyyyyyyyyyyyyyyyy" # Replace with the Prod VPC ID
}

variable "dev_private_route_table_id" {
  default = "rtb-xxxxxxxxxxxxxxxxx" # Replace with Dev Private Route Table ID
}

variable "prod_private_route_table_id" {
  default = "rtb-yyyyyyyyyyyyyyyyy" # Replace with Prod Private Route Table ID
}

variable "account2_id" {
  default = "123456789012" # Replace with Account2 AWS Account ID
}

# VPC Peering Connection (Initiated from Account 1)
resource "aws_vpc_peering_connection" "peer_dev_to_prod" {
  provider       = aws.account1
  vpc_id         = var.dev_vpc_id
  peer_vpc_id    = var.prod_vpc_id
  peer_owner_id  = var.account2_id
  auto_accept    = false # Needs to be accepted by Account2

  tags = {
    Name = "dev-to-prod-peering"
  }
}

# Accept Peering in Account 2
resource "aws_vpc_peering_connection_accepter" "accept_peer_dev_to_prod" {
  provider                   = aws.account2
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_dev_to_prod.id
  auto_accept                = true

  tags = {
    Name = "accept-dev-to-prod-peering"
  }
}

# Route Table Updates for Dev VPC (Account1)
resource "aws_route" "dev_to_prod_route" {
  provider                    = aws.account1
  route_table_id              = var.dev_private_route_table_id
  destination_cidr_block      = "10.222.2.0/24" # Update with Prod VPC CIDR
  vpc_peering_connection_id   = aws_vpc_peering_connection.peer_dev_to_prod.id
}

# Route Table Updates for Prod VPC (Account2)
resource "aws_route" "prod_to_dev_route" {
  provider                    = aws.account2
  route_table_id              = var.prod_private_route_table_id
  destination_cidr_block      = "10.200.241.0/24" # Update with Dev VPC CIDR
  vpc_peering_connection_id   = aws_vpc_peering_connection.peer_dev_to_prod.id
}

# Create Security Group in Dev VPC (Account1) - Allow SSH & RDP from Prod VPC
resource "aws_security_group" "dev_allow_ssh_rdp" {
  provider = aws.account1
  name     = "dev-allow-ssh-rdp"
  vpc_id   = var.dev_vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.222.2.0/24"] # Allow SSH from Prod VPC
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.222.2.0/24"] # Allow RDP from Prod VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "dev-allow-ssh-rdp"
  }
}

# Create Security Group in Prod VPC (Account2) - Allow SSH & RDP from Dev VPC
resource "aws_security_group" "prod_allow_ssh_rdp" {
  provider = aws.account2
  name     = "prod-allow-ssh-rdp"
  vpc_id   = var.prod_vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.200.241.0/24"] # Allow SSH from Dev VPC
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.200.241.0/24"] # Allow RDP from Dev VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "prod-allow-ssh-rdp"
  }
}
