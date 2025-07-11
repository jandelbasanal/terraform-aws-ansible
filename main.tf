provider "aws" {
  region = "ap-northeast-1"
}

module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "10.10.0.0/16"
}

module "subnet" {
  source = "./modules/subnet"
  vpc_id = module.vpc.vpc_id

  public_subnet_1_cidr = "10.10.1.0/24"
  public_subnet_2_cidr = "10.10.2.0/24"
}

module "ec2" {
  source = "./modules/ec2"

  subnet_id = module.subnet.public_subnet_1_id
  key_name  = "wtv"
}
