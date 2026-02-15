# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${aws_eks_cluster.main.name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-eks-logs-${var.environment}"
  }
}

# CloudWatch Log Group for RDS
resource "aws_db_parameter_group" "postgres" {
  name_prefix = "${var.project_name}-postgres-"
  family      = "postgres${split(".", var.rds_engine_version)[0]}"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name = "${var.project_name}-postgres-params-${var.environment}"
  }
}

# CloudWatch Alarms for EKS Node Group
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

  dimensions = {
    InstanceId = aws_eks_node_group.main.id
  }
}

# CloudWatch Alarms for RDS
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
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648  # 2GB
  alarm_description   = "Alert when RDS storage is below 2GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}