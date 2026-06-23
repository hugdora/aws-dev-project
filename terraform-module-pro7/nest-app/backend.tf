# S3 backend with DynamoDB state locking
terraform {
  backend "s3" {
    bucket         = "dora-terraform-remote-state"
    key            = "terraform-module/nest/ecs/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"    
  }
}