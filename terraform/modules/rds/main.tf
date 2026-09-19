resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-rds"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username

  # RDS generates the master password and stores it in Secrets Manager. The
  # password never passes through Terraform variables or state.
  manage_master_user_password = true

  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  multi_az               = var.multi_az

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Protected environments keep the instance from being deleted and take a
  # final snapshot on destroy. Delete a previous final snapshot of the same
  # name before destroying the same environment a second time.
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.final_snapshot
  final_snapshot_identifier = var.final_snapshot ? "${var.project_name}-${var.environment}-rds-final" : null

  # The MySQL general log records every statement and is expensive at any
  # real traffic level; error and slow query logs cover operational needs.
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds"
  })
}
