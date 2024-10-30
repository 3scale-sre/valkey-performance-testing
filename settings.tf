terraform {
  backend "local" {}
}

provider "aws" {
  region = "us-east-1"
}