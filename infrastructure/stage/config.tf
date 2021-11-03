terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.36.0"
    }
  }

  backend "s3" {
    bucket = "sch-cbt-iaac"
    key    = "ma/staging/enonic/state"
    region = "eu-central-1"
  }
}

provider "aws" {
  region              = "eu-central-1"
  allowed_account_ids = ["636059971062"]
  assume_role {
    role_arn = "arn:aws:iam::636059971062:role/cicd/ma-fulladmin"
  }
}
