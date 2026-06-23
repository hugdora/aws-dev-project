# AWS provider
provider "aws" {
  region  = "eu-west-2"
  profile = "cloud-project"

  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = "nest"
      "Environment" = "dev"
    }
  }
}