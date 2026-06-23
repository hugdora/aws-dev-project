# AWS provider
provider "aws" {
  region  = var.region
  profile = "cloud-project"

  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = var.project_name
      "Environment" = var.environment
    }
  }
}