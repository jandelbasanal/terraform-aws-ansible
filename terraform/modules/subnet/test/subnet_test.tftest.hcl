test "subnet-creation" {
  description = "Ensure both subnets are created correctly with proper CIDRs"

  provider "aws" {
    mock = true
  }

  module "subnet" {
    source = "../"
    vpc_id = "vpc-mock123"  # fake ID since we're mocking

    public_subnet_1_cidr = "10.10.1.0/24"
    public_subnet_2_cidr = "10.10.2.0/24"
  }

  assert {
    condition     = module.subnet.aws_subnet.public_1.cidr_block == "10.10.1.0/24"
    error_message = "First public subnet CIDR should be 10.10.1.0/24"
  }

  assert {
    condition     = module.subnet.aws_subnet.public_2.cidr_block == "10.10.2.0/24"
    error_message = "Second public subnet CIDR should be 10.10.2.0/24"
  }

  assert {
    condition     = can(module.subnet.aws_internet_gateway.igw.id)
    error_message = "Internet Gateway was not created"
  }
}
