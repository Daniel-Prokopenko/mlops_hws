variable "name" {
  type        = string
  description = "VPC name prefix"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDRs"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name (for subnet tags)"
}
