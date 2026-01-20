variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "project" {
  type        = string
  description = "Project name prefix"
  default     = "eks-vpc-cluster"
}

variable "environment" {
  type        = string
  description = "Environment tag"
  default     = "dev"
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.30"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs (must align with azs length)"
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDRs (must align with azs length)"
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}
