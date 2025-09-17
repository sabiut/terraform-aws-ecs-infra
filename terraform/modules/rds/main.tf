data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = [var.database_subnet_id, aws_subnet.additional_db_subnet.id]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

resource "aws_subnet" "additional_db_subnet" {
  vpc_id            = data.aws_subnet.database.vpc_id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-additional-db-subnet"
    Type = "Database"
  })
}

data "aws_subnet" "database" {
  id = var.database_subnet_id
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-rds"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds"
  })
}