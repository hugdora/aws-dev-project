# S3 backend with DynamoDB state locking
terraform {
  backend "s3" {
    bucket         = "dora-terraform-remote-state"
    key            = "nest/ec2-module/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
    profile        = "cloud-project"
  }
}