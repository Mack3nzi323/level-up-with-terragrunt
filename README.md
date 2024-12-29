# Level Up with Terragrunt

Terragrunt is a thin wrapper around Terraform that provides extra tools for working with multiple Terraform modules, remote state management, and keeping your configurations DRY(Don't Repeat Yourself). This guide demonstrates how to use Terragrunt effectively with practical examples.

## State Management

### Remote State Configuration

Terragrunt automatically manages your remote state configuration. Here's a base `terragrunt.hcl` configuration:

```hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "my-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

This configuration:
- Creates an S3 bucket for state storage if it doesn't exist
- Enables encryption by default
- Sets up DynamoDB for state locking
- Uses account ID in bucket name for multi-account setups
- Generates backend configuration automatically

## DRY Configuration with Terragrunt

### Root Configuration

Create a root Terragrunt configuration file `root.hcl` to define common configurations:

> **Note:** With the latest version of Terragrunt, the root configuration file cannot be named `terragrunt.hcl`.

```hcl
# environments/root.hcl
locals {
  environment = path_relative_to_include()
  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terragrunt"
    Owner       = "DevOps"
  }
}

inputs = {
  environment = local.environment
  tags       = local.common_tags
}
```

### VPC Module Example

Here's how to structure a VPC module with Terragrunt:

```hcl
# environments/dev/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
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
```

## Dependencies and Outputs

### Using Dependency Blocks

Terragrunt makes it easy to reference outputs from other modules:

```hcl
# environments/dev/eks/terragrunt.hcl
dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id         = "vpc-000000"
    private_subnets = ["subnet-000000", "subnet-111111"]
  }
}

inputs = {
  vpc_id          = dependency.vpc.outputs.vpc_id
  subnet_ids      = dependency.vpc.outputs.private_subnets
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.27"
}
```

The `mock_outputs` allow you to run `terragrunt plan` even when the VPC hasn't been created yet, this can be helpful for plan review before apply in production environments.

## Enforcing Standards

### Standardized Tagging

Create a helper file for tag management:

```hcl
# common/tags.hcl
locals {
  mandatory_tags = {
    Environment = get_env("TG_VAR_environment", "dev")
    Owner       = get_env("TG_VAR_owner", "DevOps")
    Project     = get_env("TG_VAR_project", "Infrastructure")
    CostCenter  = get_env("TG_VAR_cost_center", "Engineering")
  }
}
```

Use it in your modules:

```hcl
# environments/dev/vpc/terragrunt.hcl
locals {
  tags = read_terragrunt_config(find_in_parent_folders("common/tags.hcl"))
}

inputs = {
  tags = merge(
    local.tags.locals.mandatory_tags,
    {
      Component = "VPC"
    }
  )
}
```

## Project Structure

Here's the recommended project structure:

```
.
├── common/
│   └── tags.hcl
├── environments/
│   ├── terragrunt.hcl
│   ├── dev/
│   │   ├── env.hcl
│   │   ├── vpc/
│   │   │   └── terragrunt.hcl
│   │   └── eks/
│   │       └── terragrunt.hcl
│   └── prod/
│       ├── env.hcl
│       └── vpc/
│           └── terragrunt.hcl
└── modules/
    └── custom-modules/
```

## Best Practices

1. **State Organization**:
   - Use separate state files for each environment and component
   - Implement state locking with DynamoDB
   - Enable versioning on S3 state buckets

2. **Module Dependencies**:
   - Use explicit dependencies with `dependency` blocks
   - Provide mock outputs for planning
   - Keep dependency chains shallow

3. **Configuration Management**:
   - Store common configurations at the root level
   - Use environment-specific variables in `env.hcl`
   - Implement consistent tagging across all resources

4. **Security**:
   - Enable encryption for state files
   - Use IAM roles for Terragrunt execution
   - Implement strict S3 bucket policies

## Results and Impact

Implementing Terragrunt in our infrastructure has led to:
- Standardized resource tagging across all environments
- Reducedstate file conflicts with proper locking
- Simplified module dependencies and output sharing
- Consistent environment configurations
