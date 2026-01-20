terraform {
  backend "s3" {
    bucket         = "prokop-tfstate-eks-1768826795"
    key            = "mlops_hws/vpc/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-locks-eks"
    encrypt        = true
  }
}
