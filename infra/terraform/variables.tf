# ============================================
# AWS Configuration Variables
# ============================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ai-finance"
}

# ============================================
# VPC Configuration Variables
# ============================================
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks (for EKS nodes and RDS)"
  type        = list(string)
  default     = ["10.0.1.0/24"]
  # PRODUCTION: Add more subnets across AZs
  # default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks (for NAT Gateway and ALB)"
  type        = list(string)
  default     = ["10.0.101.0/24"]
  # PRODUCTION: Add more subnets across AZs
  # default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# ============================================
# EKS Cluster Configuration Variables
# ============================================
variable "eks_cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "eks_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1  # COST-OPTIMIZED
  # PRODUCTION: default = 3
}

variable "eks_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1  # COST-OPTIMIZED
  # PRODUCTION: default = 2
}

variable "eks_max_size" {
  description = "Maximum number of worker nodes (auto-scaling limit)"
  type        = number
  default     = 3  # Allow small scale-up
  # PRODUCTION: default = 20
}

variable "eks_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.small"]  # COST-OPTIMIZED: $18/month
  # PRODUCTION OPTIONS:
  # default = ["m5.large"]     # $70/month (better CPU)
  # default = ["m5.xlarge"]    # $140/month (more memory)
  # default = ["c5.large"]     # Better for CPU-heavy workloads
}

variable "eks_capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"  # Reliable for demo
  # PRODUCTION (BUDGET): default = "SPOT"  # Saves 70% but can be interrupted
}

# ============================================
# RDS Configuration Variables
# ============================================
variable "rds_engine_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16.1"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # COST-OPTIMIZED: FREE for 12 months
  # PRODUCTION OPTIONS:
  # default = "db.t3.small"    # $17/month (2GB RAM)
  # default = "db.r5.large"    # $266/month (16GB RAM, optimized)
  # default = "db.r5.xlarge"   # $532/month (32GB RAM)
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20  # FREE with AWS Free Tier
  # PRODUCTION: default = 100  # Larger storage
}

variable "rds_backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 1  # COST-OPTIMIZED: Minimal backups
  # PRODUCTION: default = 30  # Keep 30 days of backups
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ (high availability)"
  type        = bool
  default     = false  # COST-OPTIMIZED: Single AZ only
  # PRODUCTION: default = true  # Adds $18/month but much safer
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "aifinancedb"
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "database_password" {
  description = "Database password (change this!)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.database_password) >= 8
    error_message = "Database password must be at least 8 characters."
  }
}

# ============================================
# S3 Configuration Variables
# ============================================
variable "s3_bucket_versioning" {
  description = "Enable S3 versioning (costs extra)"
  type        = bool
  default     = false  # COST-OPTIMIZED
  # PRODUCTION: default = true
}

variable "s3_bucket_encryption" {
  description = "Enable S3 encryption (no cost)"
  type        = bool
  default     = true
}

# ============================================
# NAT Gateway Configuration
# ============================================
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (costs $32.40/month per AZ)"
  type        = bool
  default     = false  # COST-OPTIMIZED: Use VPC Endpoints instead
  # PRODUCTION: default = true
}

# ============================================
# Tags Variables
# ============================================
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "ai-finance"
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-02-15"
  }
}