# ============================================
# RDS Subnet Group (Multi-AZ support)
# ============================================
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  }
}

# ============================================
# RDS PostgreSQL Instance
# ============================================
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-postgres-${var.environment}"
  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  # Storage configuration
  allocated_storage = var.rds_allocated_storage
  storage_type      = "gp3" # General Purpose (most cost-effective)
  storage_encrypted = true

  # Database
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Backups (minimal for DEMO to save costs)
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Snapshots
  skip_final_snapshot       = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment != "dev" ? "${var.project_name}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # High Availability (DISABLED for DEMO to save costs)
  # Enabling Multi-AZ adds $18/month
  multi_az = var.rds_multi_az

  # Access control
  publicly_accessible   = false
  copy_tags_to_snapshot = true
  deletion_protection   = var.environment == "prod" ? true : false

  # Performance Insights (OPTIONAL - costs extra)
  # Uncomment for production monitoring:
  # performance_insights_enabled          = var.environment == "prod" ? true : false
  # performance_insights_retention_period = 7

  tags = {
    Name = "${var.project_name}-postgres-${var.environment}"
  }
}