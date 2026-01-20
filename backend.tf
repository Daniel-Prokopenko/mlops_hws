# Backend для кореневого стейту (приклад на S3 + DynamoDB).
# 1) Створи S3 bucket і DynamoDB table (lock table)
# 2) Заповни значення нижче (bucket/key/region/table)
#
# Порада: ключ роби унікальним під проєкт (наприклад: "eks-vpc-cluster/root/terraform.tfstate")

terraform {
  backend "s3" {
    bucket         = "YOUR_TFSTATE_BUCKET"
    key            = "eks-vpc-cluster/root/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "YOUR_TFSTATE_LOCK_TABLE"
    encrypt        = true
  }
}
