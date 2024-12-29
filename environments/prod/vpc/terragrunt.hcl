# environments/dev/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=5.0.0"
}

inputs = {
  name = "main-vpc-${local.environment_vars.locals.environment}"
  
  cidr = "10.0.0.0/16"
  
  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true
  
  # Tags from root configuration are automatically merged
  additional_tags = {
    Component = "Networking"
  }
}