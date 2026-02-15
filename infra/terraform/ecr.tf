# ECR Repository for each service
resource "aws_ecr_repository" "services" {
  for_each = toset([
    "auth-service",
    "upload-service",
    "parser-worker",
    "analytics-service",
    "ai-service"
  ])

  name                 = "${var.project_name}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-${each.value}-${var.environment}"
  }
}

# ECR Lifecycle Policy (keep only 10 latest images)
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}