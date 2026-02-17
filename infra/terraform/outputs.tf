# ============================================
# VPC Outputs
# ============================================
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for EKS nodes and RDS)"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (for ALB)"
  value       = aws_subnet.public[*].id
}

# ============================================
# EKS Cluster Outputs
# ============================================
output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_arn" {
  description = "EKS Cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_version" {
  description = "EKS Cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "eks_node_group_name" {
  description = "EKS Node Group name"
  value       = aws_eks_node_group.main.node_group_name
}

output "eks_node_group_arn" {
  description = "EKS Node Group ARN"
  value       = aws_eks_node_group.main.arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
}

output "eks_cluster_certificate_authority" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

# ============================================
# RDS PostgreSQL Outputs
# ============================================
output "rds_endpoint" {
  description = "RDS endpoint (hostname:port)"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS hostname only"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "rds_database_username" {
  description = "RDS database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "rds_instance_class" {
  description = "RDS instance class"
  value       = aws_db_instance.main.instance_class
}

output "rds_engine_version" {
  description = "RDS PostgreSQL engine version"
  value       = aws_db_instance.main.engine_version
}

output "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  value       = aws_db_instance.main.allocated_storage
}

output "rds_storage_type" {
  description = "RDS storage type"
  value       = aws_db_instance.main.storage_type
}

output "database_connection_string" {
  description = "Full PostgreSQL connection string"
  value       = "postgresql://${var.database_username}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.database_name}"
  sensitive   = true
}

output "database_connection_string_with_password" {
  description = "PostgreSQL connection string with password (SENSITIVE)"
  value       = "postgresql://${var.database_username}:${var.database_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.database_name}"
  sensitive   = true
}

output "rds_multi_az" {
  description = "RDS Multi-AZ enabled"
  value       = aws_db_instance.main.multi_az
}

output "rds_backup_retention_period" {
  description = "RDS backup retention period (days)"
  value       = aws_db_instance.main.backup_retention_period
}

# ============================================
# S3 Bucket Outputs
# ============================================
output "s3_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = aws_s3_bucket.uploads.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.uploads.arn
}

output "s3_bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.uploads.region
}

output "s3_bucket_versioning_enabled" {
  description = "S3 bucket versioning status"
  value       = var.s3_bucket_versioning ? "Enabled" : "Disabled"
}

# ============================================
# ECR Repository Outputs
# ============================================
output "ecr_repositories" {
  description = "ECR repositories for all services"
  value = {
    for service, repo in aws_ecr_repository.services :
    service => {
      repository_url = repo.repository_url
      repository_arn = repo.arn
      registry_id    = repo.registry_id
    }
  }
}

output "ecr_registry_url" {
  description = "ECR registry base URL"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# ============================================
# ALB Outputs
# ============================================
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route 53)"
  value       = aws_lb.main.zone_id
}

output "alb_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_listener_http_arn" {
  description = "ARN of HTTP listener"
  value       = aws_lb_listener.http.arn
}

# ============================================
# Security Groups Outputs
# ============================================
output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster control plane"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS database"
  value       = aws_security_group.rds.id
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "vpc_endpoint_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoint.id
}

# ============================================
# IAM Outputs
# ============================================
output "eks_cluster_iam_role_arn" {
  description = "ARN of EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_nodes_iam_role_arn" {
  description = "ARN of EKS nodes IAM role"
  value       = aws_iam_role.eks_nodes.arn
}

output "app_iam_role_arn" {
  description = "ARN of application IAM role (for IRSA)"
  value       = aws_iam_role.app_role.arn
}

output "app_iam_role_name" {
  description = "Name of application IAM role"
  value       = aws_iam_role.app_role.name
}

output "eks_oidc_provider_arn" {
  description = "ARN of EKS OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# ============================================
# VPC Endpoints Outputs
# ============================================
output "s3_vpc_endpoint_id" {
  description = "S3 Gateway VPC Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "ecr_api_vpc_endpoint_id" {
  description = "ECR API Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_vpc_endpoint_id" {
  description = "ECR DKR Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "logs_vpc_endpoint_id" {
  description = "CloudWatch Logs Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.logs.id
}

# ============================================
# CloudWatch Outputs
# ============================================
output "eks_cloudwatch_log_group_name" {
  description = "CloudWatch log group name for EKS cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "eks_cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for EKS cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}

# ============================================
# AWS Account & Region Outputs
# ============================================
output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# ============================================
# Useful Commands
# ============================================
output "useful_commands" {
  description = "Useful commands to interact with the infrastructure"
  value = {
    configure_kubectl = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
    ecr_login         = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    list_nodes        = "kubectl get nodes"
    list_pods         = "kubectl get pods -n ai-finance"
    check_alb_status  = "aws elbv2 describe-load-balancers --names ${aws_lb.main.name} --region ${var.aws_region}"
    test_api          = "curl http://${aws_lb.main.dns_name}/health"
  }
}

# ============================================
# Summary Output
# ============================================
output "summary" {
  description = "Summary of created infrastructure"
  value = {
    cluster_name    = aws_eks_cluster.main.name
    cluster_version = aws_eks_cluster.main.version
    database_host   = aws_db_instance.main.address
    database_name   = aws_db_instance.main.db_name
    s3_bucket       = aws_s3_bucket.uploads.id
    alb_dns         = aws_lb.main.dns_name
    ecr_registry    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    aws_account     = data.aws_caller_identity.current.account_id
    region          = var.aws_region
    environment     = var.environment
  }
}