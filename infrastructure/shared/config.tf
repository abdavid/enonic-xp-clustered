terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.36.0"
    }
  }

  backend "s3" {
    bucket = "sch-cbt-iaac"
    key    = "ma/production/enonic-shared/state"
    region = "eu-central-1"
  }
}

provider "aws" {
  region              = "eu-central-1"
  allowed_account_ids = ["953355806585"]
  assume_role {
    role_arn = "arn:aws:iam::953355806585:role/cicd/ma-fulladmin"
  }
}
