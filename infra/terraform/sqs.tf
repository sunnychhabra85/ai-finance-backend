# ============================================
# AWS SQS Queues for All Environments
# ============================================

# Transactions Queue
resource "aws_sqs_queue" "transactions_queue" {
  name                      = "${var.project_name}-transactions-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.transactions_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project_name}-transactions-queue-${var.environment}"
    Environment = var.environment
  }
}

# Transactions Dead Letter Queue
resource "aws_sqs_queue" "transactions_dlq" {
  name                      = "${var.project_name}-transactions-dlq-${var.environment}"
  message_retention_seconds = 1209600

  tags = {
    Name        = "${var.project_name}-transactions-dlq-${var.environment}"
    Environment = var.environment
  }
}

# Analytics Queue
resource "aws_sqs_queue" "analytics_queue" {
  name                      = "${var.project_name}-analytics-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.analytics_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project_name}-analytics-queue-${var.environment}"
    Environment = var.environment
  }
}

# Analytics Dead Letter Queue
resource "aws_sqs_queue" "analytics_dlq" {
  name                      = "${var.project_name}-analytics-dlq-${var.environment}"
  message_retention_seconds = 1209600

  tags = {
    Name        = "${var.project_name}-analytics-dlq-${var.environment}"
    Environment = var.environment
  }
}

# ============================================
# IAM Policy for SQS Access
# ============================================

resource "aws_iam_role_policy" "app_sqs_policy" {
  name_prefix = "${var.project_name}-app-sqs-"
  role        = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          aws_sqs_queue.transactions_queue.arn,
          aws_sqs_queue.transactions_dlq.arn,
          aws_sqs_queue.analytics_queue.arn,
          aws_sqs_queue.analytics_dlq.arn
        ]
      }
    ]
  })
}

# ============================================
# Outputs
# ============================================

output "sqs_transactions_queue_url" {
  description = "Transactions SQS Queue URL"
  value       = aws_sqs_queue.transactions_queue.url
}

output "sqs_analytics_queue_url" {
  description = "Analytics SQS Queue URL"
  value       = aws_sqs_queue.analytics_queue.url
}

output "sqs_transactions_dlq_url" {
  description = "Transactions DLQ URL"
  value       = aws_sqs_queue.transactions_dlq.url
}

output "sqs_analytics_dlq_url" {
  description = "Analytics DLQ URL"
  value       = aws_sqs_queue.analytics_dlq.url
}