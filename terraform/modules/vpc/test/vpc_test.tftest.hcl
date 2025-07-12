test "basic-vpc-creation" {
  description = "Ensure the VPC is created with the correct CIDR block"

  provider "aws" {
    mock = true
  }

  module "vpc" {
    source    = "../"
    vpc_cidr  = "10.10.0.0/16"
  }

  assert {
    condition     = module.vpc.aws_vpc.main.cidr_block == "10.10.0.0/16"
    error_message = "VPC CIDR block must be 10.10.0.0/16"
  }

  assert {
    condition     = can(module.vpc.aws_vpc.main.id)
    error_message = "VPC resource was not created"
  }
}
