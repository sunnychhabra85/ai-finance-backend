# ============================================
# CloudWatch Log Group for EKS Cluster
# ============================================
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${aws_eks_cluster.main.name}"
  retention_in_days = 7 # COST-OPTIMIZED: Keep logs for 7 days only
  # PRODUCTION: retention_in_days = 30  # Keep for 30 days

  tags = {
    Name = "${var.project_name}-eks-logs-${var.environment}"
  }
}

# ============================================
# CloudWatch Alarms (FREE - Important for monitoring)
# ============================================

# EKS Cluster - Node CPU Alert
resource "aws_cloudwatch_metric_alarm" "eks_nodes_cpu" {
  alarm_name          = "${var.project_name}-eks-nodes-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when EKS nodes CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  # Uncomment to add SNS notification
  # alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-eks-cpu-alarm-${var.environment}"
  }
}

# RDS Database - CPU Alert
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-rds-cpu-alarm-${var.environment}"
  }
}

# RDS Database - Storage Alert
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2GB
  alarm_description   = "Alert when RDS storage below 2GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-rds-storage-alarm-${var.environment}"
  }
}

# ============================================
# Optional: SNS Topic for Alarm Notifications
# ============================================
# Uncomment to receive email alerts when alarms trigger

# resource "aws_sns_topic" "alerts" {
#   name = "${var.project_name}-alerts-${var.environment}"
# 
#   tags = {
#     Name = "${var.project_name}-alerts-${var.environment}"
#   }
# }
# 
# resource "aws_sns_topic_subscription" "alerts_email" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = "your-email@example.com"  # Change this!
# }