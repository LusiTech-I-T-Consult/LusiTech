terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    #Configure your backend for state storage
    bucket         = "dr-pilot-light2020"
    key            = "dr-pilot-light/terraform.tfstate"
    region         = "eu-west-1"
    profile        = "default"
    dynamodb_table = "terraform-state-lock"
  }
}
