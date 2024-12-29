locals {
  environment = "prod"
  region = "us-west-2"
  tags = {
    Environment = local.environment
    ManagedBy   = "Terragrunt"
    Owner       = "DevOps"
  }
}