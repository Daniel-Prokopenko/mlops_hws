variable "region" {
  description = "AWS region where the EKS cluster lives"
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "infra-tools"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "argocd"
}
