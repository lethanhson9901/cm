terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "app-source"
      ManagedBy   = "terraform"
    }
  }
}

# VPC Module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "${var.project_name}-${var.environment}"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "prod"
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
}

# Security Groups
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

# EC2 Instances
module "ec2" {
  source = "./modules/ec2"

  instance_count  = var.environment == "prod" ? 2 : 1
  instance_type   = var.environment == "prod" ? "t3.small" : "t3.micro"
  subnet_ids      = module.vpc.private_subnets
  security_groups = [module.security_groups.app_sg_id]
  
  user_data = templatefile("${path.module}/templates/user-data.sh", {
    environment = var.environment
    region      = var.aws_region
  })

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}

# ALB
module "alb" {
  source = "./modules/alb"

  name               = "${var.project_name}-${var.environment}"
  vpc_id             = module.vpc.vpc_id
  subnets           = module.vpc.public_subnets
  security_groups    = [module.security_groups.alb_sg_id]
  target_group_arns  = module.ec2.instance_ids
  
  access_logs = {
    bucket = aws_s3_bucket.alb_logs.id
    prefix = "alb-logs"
  }
}

# RDS
module "rds" {
  source = "./modules/rds"

  identifier     = "${var.project_name}-${var.environment}"
  engine         = "postgres"
  engine_version = "13.7"
  instance_class = var.environment == "prod" ? "db.t3.medium" : "db.t3.micro"
  
  allocated_storage     = 20
  storage_encrypted     = true
  
  subnet_ids           = module.vpc.private_subnets
  security_group_ids   = [module.security_groups.db_sg_id]
  
  backup_retention_period = var.environment == "prod" ? 7 : 1
  deletion_protection     = var.environment == "prod"
  
  tags = {
    Environment = var.environment
  }
}

# S3 Buckets with encryption
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-alb-logs-${var.environment}"
  
  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  lifecycle_rule {
    enabled = true
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    expiration {
      days = 90
    }
  }
}
