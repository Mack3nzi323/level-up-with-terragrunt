# environments/root.hcl
include "env" {
  path = find_in_parent_folders("env.hcl")
}

locals {
  account_id = get_aws_account_id()
  environment = path_relative_to_include()
  region = include.env.locals.region
  common_tags = {
    Environment = include.env.locals.environment
    ManagedBy   = include.env.locals.tags.ManagedBy
    Owner       = include.env.locals.tags.Owner
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "my-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# We can generate our provider.tf file here, when sourced from other terragrunt files it will setup the provider for us
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = local.region
  default_tags {
    tags = local.common_tags
  }
}
EOF
}

inputs = {
  account_id  = local.account_id
  environment = local.environment
  region      = local.region
  tags        = local.common_tags
}
