terraform {
  required_version = ">= 1.0"
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

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zone  = var.availability_zone
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  database_subnet_cidr = var.database_subnet_cidr

  tags = local.common_tags
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  tags = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  public_subnet_id       = module.networking.public_subnet_id
  alb_security_group_id  = module.security.alb_security_group_id

  tags = local.common_tags
}

module "rds" {
  source = "./modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  database_subnet_id     = module.networking.database_subnet_id
  rds_security_group_id  = module.security.rds_security_group_id
  db_instance_class      = var.db_instance_class
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password

  tags = local.common_tags
}

module "ecs" {
  source = "./modules/ecs"

  project_name                   = var.project_name
  environment                    = var.environment
  vpc_id                         = module.networking.vpc_id
  public_subnet_id               = module.networking.public_subnet_id
  private_subnet_id              = module.networking.private_subnet_id
  frontend_security_group_id     = module.security.frontend_security_group_id
  backend_security_group_id      = module.security.backend_security_group_id

  # Blue/Green Target Group ARNs
  frontend_blue_target_group_arn  = module.alb.frontend_blue_target_group_arn
  frontend_green_target_group_arn = module.alb.frontend_green_target_group_arn
  backend_blue_target_group_arn   = module.alb.backend_blue_target_group_arn
  backend_green_target_group_arn  = module.alb.backend_green_target_group_arn

  # Legacy for backward compatibility
  alb_target_group_arn           = module.alb.target_group_arn

  rds_endpoint                   = module.rds.rds_endpoint
  db_secret_arn                  = module.rds.db_secret_arn
  db_name                        = var.db_name

  tags = local.common_tags
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}