provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  name = "${var.project}-${var.environment}"
}

module "vpc" {
  source = "./vpc"

  name            = local.name
  cidr            = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  cluster_name    = local.name
}

module "eks" {
  source = "./eks"

  region          = var.region
  cluster_name    = local.name
  cluster_version = var.cluster_version

  # У режимі root-apply ми передаємо VPC напряму (швидко і без двох apply)
  use_remote_state   = false
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  depends_on = [module.vpc]
}
