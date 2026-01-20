data "terraform_remote_state" "vpc" {
  count   = var.use_remote_state ? 1 : 0
  backend = "s3"

  config = {
    bucket         = var.remote_state_bucket
    key            = var.remote_state_key
    region         = var.remote_state_region
    dynamodb_table = var.remote_state_dynamodb_table
    encrypt        = true
  }
}

locals {
  vpc_id = var.use_remote_state ? data.terraform_remote_state.vpc[0].outputs.vpc_id : var.vpc_id

  private_subnet_ids = var.use_remote_state ? (
    try(data.terraform_remote_state.vpc[0].outputs.private_subnet_ids, [])
  ) : var.private_subnet_ids
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    cpu = {
      name           = "${var.cluster_name}-cpu"
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      instance_types = ["t3.micro"]

      labels = {
        workload = "cpu"
      }
    }

    gpu = {
      name           = "${var.cluster_name}-gpu"
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      instance_types = ["t3.micro"]

      labels = {
        workload = "gpu"
      }

      taints = [
        {
          key    = "workload"
          value  = "gpu"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}

resource "null_resource" "kubeconfig" {
  triggers = {
    cluster_name = module.eks.cluster_name
    region       = var.region
  }

  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
  }

  depends_on = [module.eks]
}
