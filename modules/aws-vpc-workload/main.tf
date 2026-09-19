locals {
  common_tags = merge(
    var.config.tags,
    {
      Environment = var.config.environment
      ManagedBy   = "Terraform"
      Module      = "aws-vpc-workload"
    }
  )

  # Calculate subnets using cidrsubnets function dynamically based on the IPAM assigned CIDR
  # Assuming 3 Private App, 3 Private Data, and 3 Transit (TGW) subnets if 3 AZs.
  # We use the base VPC CIDR and split it.
}

# ------------------------------------------------------------------------------
# VPC (IPAM Managed)
# ------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  ipv4_ipam_pool_id   = var.config.ipv4_ipam_pool_id
  ipv4_netmask_length = var.config.ipv4_netmask_length

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = var.config.vpc_name })
}

# ------------------------------------------------------------------------------
# Default Security Group (Deny All)
# ------------------------------------------------------------------------------
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  # Explicitly remove all rules (Deny all by default)
  tags = merge(local.common_tags, { Name = "${var.config.vpc_name}-default-sg" })
}

# ------------------------------------------------------------------------------
# Historical prototype retained for comparison only; disabled by ADR 0014.
# ------------------------------------------------------------------------------
# Since we receive an IPAM CIDR, we compute subnet CIDRs dynamically.
# For simplicity in this base module, we carve the VPC into chunks:
# /24s or /26s depending on the VPC netmask. Here we use `cidrsubnet`.

locals {
  az_count = length(var.config.azs)
  # Example: if VPC is /20, we can add 4 bits to get /24 subnets.
  # If VPC is /24, we add 3 bits to get /27 subnets.
  newbits = var.config.ipv4_netmask_length <= 21 ? 4 : 3
}

resource "aws_subnet" "private_app" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, local.newbits, count.index)
  availability_zone = var.config.azs[count.index]

  tags = merge(local.common_tags, { Name = "${var.config.vpc_name}-private-app-${var.config.azs[count.index]}" })
}

resource "aws_subnet" "private_data" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, local.newbits, count.index + local.az_count)
  availability_zone = var.config.azs[count.index]

  tags = merge(local.common_tags, { Name = "${var.config.vpc_name}-private-data-${var.config.azs[count.index]}" })
}

resource "aws_subnet" "transit" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, local.newbits, count.index + (local.az_count * 2))
  availability_zone = var.config.azs[count.index]

  tags = merge(local.common_tags, { Name = "${var.config.vpc_name}-transit-${var.config.azs[count.index]}" })
}

# ------------------------------------------------------------------------------
# Historical NAT topology; not an approved egress model and disabled by ADR 0014.
# ------------------------------------------------------------------------------
# Note: Because this VPC has NO public subnets (per requirements), we rely on
# Transit Gateway to route 0.0.0.0/0 to an external NAT/Egress VPC, OR we place 
# NATs here if allowed. The brief says "Decentralized NAT Gateways". To have a NAT 
# Gateway, it MUST be in a subnet with an IGW. 
# Therefore, IF we are using decentralized NATs, we *must* have public subnets for them.
# The brief says: "No public subnets in workload VPCs except where an ADR justifies it".
# Let's create Public Subnets specifically for the NAT Gateways.

resource "aws_internet_gateway" "igw" {
  count  = var.config.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.config.vpc_name}-igw" })
}

resource "aws_subnet" "public_nat" {
  count             = var.config.enable_nat_gateway ? local.az_count : 0
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, local.newbits, count.index + (local.az_count * 3))
  availability_zone = var.config.azs[count.index]

  tags = merge(local.common_tags, { Name = "${var.config.vpc_name}-public-nat-${var.config.azs[count.index]}" })
}

resource "aws_eip" "nat" {
  count  = var.config.enable_nat_gateway ? local.az_count : 0
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${var.config.vpc_name}-nat-${var.config.azs[count.index]}" })
}

resource "aws_nat_gateway" "this" {
  count         = var.config.enable_nat_gateway ? local.az_count : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_nat[count.index].id

  tags       = merge(local.common_tags, { Name = "${var.config.vpc_name}-nat-${var.config.azs[count.index]}" })
  depends_on = [aws_internet_gateway.igw]
}

# ------------------------------------------------------------------------------
# Routing
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  count  = var.config.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = merge(local.common_tags, { Name = "${var.config.vpc_name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = var.config.enable_nat_gateway ? local.az_count : 0
  subnet_id      = aws_subnet.public_nat[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private_app" {
  count  = local.az_count
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${var.config.vpc_name}-private-app-rt-${var.config.azs[count.index]}" })
}

resource "aws_route" "private_nat_gateway" {
  count                  = var.config.enable_nat_gateway ? local.az_count : 0
  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private_app" {
  count          = local.az_count
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}
