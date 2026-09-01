terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  # Configure backend for real use; kept local for demo.
  # backend "s3" { bucket = "rishav-tfstate", key = "cms/dev.tfstate", region = "ap-south-1" }
}

provider "aws" {
  region = var.region
}

locals {
  name = "cms-${var.environment}"
  tags = {
    Project     = "headless-cms"
    Environment = var.environment
    Owner       = "RishavSingh-09"
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source          = "../../modules/vpc"
  name            = local.name
  cidr            = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  cluster_name    = local.name
  tags            = local.tags
}

module "eks" {
  source             = "../../modules/eks"
  cluster_name       = local.name
  k8s_version        = var.k8s_version
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  instance_types     = var.node_instance_types
  desired_size       = var.node_desired_size
  min_size           = var.node_min_size
  max_size           = var.node_max_size
  tags               = local.tags
}

module "rds" {
  source           = "../../modules/rds"
  name             = local.name
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  allowed_cidrs    = [var.vpc_cidr]
  instance_class   = var.db_instance_class
  password         = var.db_password
  multi_az         = var.db_multi_az
  tags             = local.tags
}

module "iam" {
  source       = "../../modules/iam"
  name         = local.name
  media_bucket = "${local.name}-media"
  tags         = local.tags
}
