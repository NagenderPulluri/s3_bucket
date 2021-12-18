# Terraform version
terraform {
  required_version = ">= 0.12.0"

  required_providers {
    aws = ">= 3.28"
  }
}
provider "aws" {
  region = "us-east-1"
}

