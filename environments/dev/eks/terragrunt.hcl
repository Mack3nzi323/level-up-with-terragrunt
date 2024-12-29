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