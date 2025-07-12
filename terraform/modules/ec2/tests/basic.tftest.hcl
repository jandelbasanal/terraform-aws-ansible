test "basic-ec2-test" {
  description = "Validates that an EC2 instance is created"

  # This uses a mocked AWS provider, not the real one
  provider "aws" {
    mock = true
  }

  module "ec2" {
    source    = "../"
    subnet_id = "subnet-mock123"
    key_name  = "wtv"
  }

  assert {
    condition     = module.ec2.aws_instance.ubuntu.ami != ""
    error_message = "AMI should not be empty"
  }

  assert {
    condition     = module.ec2.aws_instance.ubuntu.instance_type == "t2.micro"
    error_message = "Instance type should be t2.micro"
  }
}
