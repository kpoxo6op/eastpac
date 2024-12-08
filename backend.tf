terraform {
  backend "s3" {
    bucket         = "terraform-state-mwaa"
    key            = "mwaa/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-mwaa-locks"
  }
} 