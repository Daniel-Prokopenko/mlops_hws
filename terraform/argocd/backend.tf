# Optional: configure remote backend here (S3 + DynamoDB) if you use it.
# terraform {
#   backend "s3" {
#     bucket         = "<your-tf-state-bucket>"
#     key            = "argocd/terraform.tfstate"
#     region         = "eu-central-1"
#     dynamodb_table = "<your-lock-table>"
#     encrypt        = true
#   }
# }
