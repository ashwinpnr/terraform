terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = ".aws/cred"
}

module "testing-environment" {
  source       = "./test-environment"
  default_tags = var.default_tags
}
