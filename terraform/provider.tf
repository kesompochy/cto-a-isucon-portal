provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket = "isu-aws-tfstate"
    key    = "portal.tfstate"
    region = "ap-northeast-1"
  }
}