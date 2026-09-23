terraform {
  # terraform_data (used to replace the port-80 listener when HTTPS is
  # turned on or off) needs 1.4.
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure via terraform init with backend-config flags or terraform.tfvars
    # bucket         = "your-terraform-state-bucket"
    # key            = "terraform.tfstate"
    # region         = "ap-southeast-2"
    # dynamodb_table = "terraform-state-locks"
    # encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "./modules/networking"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  tags = local.common_tags
}

module "security" {
  source = "./modules/security"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  test_listener_port        = var.test_listener_port
  test_listener_cidr_blocks = var.test_listener_cidr_blocks

  tags = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  project_name               = var.project_name
  short_name                 = var.short_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  alb_security_group_id      = module.security.alb_security_group_id
  certificate_arn            = var.certificate_arn
  test_listener_port         = var.test_listener_port
  frontend_health_check_path = var.frontend_health_check_path
  backend_health_check_path  = var.backend_health_check_path

  tags = local.common_tags
}

module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  database_subnet_ids   = module.networking.database_subnet_ids
  rds_security_group_id = module.security.rds_security_group_id
  db_instance_class     = var.db_instance_class
  db_name               = var.db_name
  db_username           = var.db_username
  multi_az              = var.db_multi_az
  deletion_protection   = local.is_production
  final_snapshot        = local.is_production

  tags = local.common_tags
}

module "ecs" {
  source = "./modules/ecs"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  private_subnet_ids         = module.networking.private_subnet_ids
  frontend_security_group_id = module.security.frontend_security_group_id
  backend_security_group_id  = module.security.backend_security_group_id

  frontend_cpu           = var.frontend_cpu
  frontend_memory        = var.frontend_memory
  backend_cpu            = var.backend_cpu
  backend_memory         = var.backend_memory
  frontend_desired_count = var.frontend_desired_count
  backend_desired_count  = var.backend_desired_count
  log_retention_days     = var.log_retention_days

  # Blue/Green Target Group ARNs. These outputs also carry a dependency on
  # the ALB listeners, so the services are not created before their target
  # groups are attached to the load balancer.
  frontend_blue_target_group_arn  = module.alb.frontend_blue_target_group_arn
  frontend_green_target_group_arn = module.alb.frontend_green_target_group_arn
  backend_blue_target_group_arn   = module.alb.backend_blue_target_group_arn
  backend_green_target_group_arn  = module.alb.backend_green_target_group_arn

  frontend_image   = var.frontend_image
  frontend_command = var.frontend_command
  backend_image    = var.backend_image
  backend_command  = var.backend_command

  rds_endpoint  = module.rds.rds_endpoint
  db_secret_arn = module.rds.db_secret_arn
  db_name       = var.db_name

  tags = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name              = var.project_name
  environment               = var.environment
  alb_arn_suffix            = module.alb.alb_arn_suffix
  target_group_arn_suffixes = module.alb.target_group_arn_suffixes
  rds_identifier            = module.rds.rds_identifier
  db_secret_redeploy_arn    = module.ecs.db_secret_redeploy_state_machine_arn
  alarm_email               = var.alarm_email
  alarm_actions             = var.alarm_actions

  tags = local.common_tags
}

locals {
  # Production gets deletion protection and a final RDS snapshot. The destroy
  # workflow deliberately does not offer prod, matching this.
  is_production = var.environment == "prod"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# The RDS module used to create its own second database subnet. It now lives
# in the networking module; keep the existing subnet rather than replacing it.
moved {
  from = module.rds.aws_subnet.additional_db_subnet
  to   = module.networking.aws_subnet.database[1]
}
