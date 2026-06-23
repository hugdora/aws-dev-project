# AWS provider
provider "aws" {
  region  = "eu-west-2"
 

  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = "nest"
      "Environment" = "dev"
    }
  }
}