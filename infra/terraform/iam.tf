# ============================================
# IAM Role for Applications (IRSA)
# ============================================
# Allows Kubernetes pods to access AWS services
resource "aws_iam_role" "app_role" {
  name_prefix = "${var.project_name}-app-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:ai-finance:app-sa"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-app-role-${var.environment}"
  }
}

# ============================================
# S3 Access Policy
# ============================================
resource "aws_iam_role_policy" "app_s3_policy" {
  name_prefix = "${var.project_name}-app-s3-"
  role        = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.uploads.arn,
          "${aws_s3_bucket.uploads.arn}/*"
        ]
      }
    ]
  })
}

# ============================================
# ECR Access Policy
# ============================================
resource "aws_iam_role_policy" "app_ecr_policy" {
  name_prefix = "${var.project_name}-app-ecr-"
  role        = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================
# CloudWatch Logs Access Policy
# ============================================
resource "aws_iam_role_policy" "app_logs_policy" {
  name_prefix = "${var.project_name}-app-logs-"
  role        = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/*"
      }
    ]
  })
}

# ============================================
# Outputs
# ============================================
output "app_role_arn" {
  description = "IAM role ARN for applications"
  value       = aws_iam_role.app_role.arn
}

output "app_role_name" {
  description = "IAM role name for applications"
  value       = aws_iam_role.app_role.name
}