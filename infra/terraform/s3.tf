# ============================================
# S3 Bucket for File Uploads
# ============================================
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}-uploads-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-uploads-${var.environment}"
  }
}

# ============================================
# S3 Versioning (COST-OPTIMIZED: DISABLED)
# ============================================
# Versioning costs: $0.023 per GB for each version
# Disable for demo to save costs
resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = var.s3_bucket_versioning ? "Enabled" : "Suspended"
    # PRODUCTION: change to Enabled for data protection
  }
}

# ============================================
# S3 Encryption (NO COST)
# ============================================
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Free encryption
      # PRODUCTION: Use KMS for better security (costs extra)
      # sse_algorithm = "aws:kms"
      # kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

# ============================================
# S3 Block Public Access (SECURITY)
# ============================================
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================
# S3 Lifecycle Policy (AUTO-DELETE OLD FILES)
# ============================================
# Delete files after 90 days to save storage costs
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "delete-old-uploads"
    status = "Enabled"

    # Delete uploaded files after 90 days
    expiration {
      days = 90
    }

    # Delete old versions after 30 days (if versioning enabled)
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ============================================
# S3 Bucket Policy (ACCESS CONTROL)
# ============================================
resource "aws_s3_bucket_policy" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.uploads.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid    = "AllowEKSNodeAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.eks_nodes.arn
        }
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
# Outputs
# ============================================
output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.uploads.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.uploads.arn
}