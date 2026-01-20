variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.30"
}

# --------- VPC inputs (direct) ----------
variable "vpc_id" {
  type        = string
  description = "VPC ID (direct input)"
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for nodes (direct input)"
  default     = null
}

# --------- Remote state (optional) ----------
variable "use_remote_state" {
  type        = bool
  description = "If true, read VPC outputs via terraform_remote_state"
  default     = true
}

variable "remote_state_bucket" {
  type        = string
  description = "S3 bucket with VPC state"
  default     = "YOUR_TFSTATE_BUCKET"
}

variable "remote_state_key" {
  type        = string
  description = "S3 key for VPC state"
  default     = "eks-vpc-cluster/vpc/terraform.tfstate"
}

variable "remote_state_region" {
  type        = string
  description = "S3 region for VPC state"
  default     = "eu-central-1"
}

variable "remote_state_dynamodb_table" {
  type        = string
  description = "DynamoDB table for state lock (optional)"
  default     = "YOUR_TFSTATE_LOCK_TABLE"
}
