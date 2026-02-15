# ============================================
# VPC Core Configuration
# ============================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# Internet Gateway (NO COST)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
  }
}

# ============================================
# VPC Endpoints (COST-OPTIMIZED Alternative to NAT)
# ============================================
# VPC Endpoints allow private subnets to access AWS services
# without going through NAT Gateway (saves $32.40/month per AZ)

# S3 Gateway Endpoint (NO COST - only gateway endpoint)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids   = concat(aws_route_table.private[*].id, [aws_route_table.public[0].id])

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-s3-endpoint-${var.environment}"
  }
}

# ECR API Endpoint (costs $7.20/month)
# REQUIRED: EKS nodes need this to pull Docker images
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ecr-api-endpoint-${var.environment}"
  }
}

# ECR DKR Endpoint (costs $7.20/month)
# REQUIRED: For pulling images from ECR
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ecr-dkr-endpoint-${var.environment}"
  }
}

# CloudWatch Logs Endpoint (costs $7.20/month)
# REQUIRED: For container logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-logs-endpoint-${var.environment}"
  }
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "${var.project_name}-vpc-ep-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for VPC endpoints"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoint-sg-${var.environment}"
  }
}

# ============================================
# Public Subnets (For ALB and NAT Gateway)
# ============================================
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                             = "${var.project_name}-public-subnet-${var.environment}-${count.index + 1}"
    "kubernetes.io/role/elb"         = "1"
  }
}

# ============================================
# Private Subnets (For EKS nodes and RDS)
# ============================================
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                    = "${var.project_name}-private-subnet-${var.environment}-${count.index + 1}"
    "kubernetes.io/role/internal-elb"       = "1"
  }
}

# ============================================
# NAT Gateway (OPTIONAL - COST: $32.40/month per AZ)
# ============================================
# For DEMO: DISABLED (we use VPC Endpoints instead)
# For PRODUCTION: Enable if you need outbound internet access

# Elastic IPs for NAT Gateway (only if enabled)
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-eip-nat-${var.environment}-${count.index + 1}"
  }
}

# NAT Gateways (only if enabled)
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-${var.environment}-${count.index + 1}"
  }
}

# ============================================
# Route Table for Public Subnets
# ============================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Route Tables for Private Subnets
# ============================================
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  # CONDITIONAL: Only add NAT route if NAT Gateway is enabled
  # For DEMO (default): NAT is disabled, so no outbound internet
  # For PRODUCTION: Uncomment to enable NAT Gateway
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.environment}-${count.index + 1}"
  }
}

# Associate Private Subnets with Private Route Tables
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ============================================
# Output: VPC Details
# ============================================
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for EKS"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  value       = aws_subnet.public[*].id
}