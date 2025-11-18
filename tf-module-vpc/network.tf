provider "aws" {
    region = "ap-south-1"
}

data "aws_availability_zones" "name" {
    state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = "my-vpc"
  cidr = "11.0.0.0/16"



  azs = data.aws_availability_zones.name.names
  public_subnets = ["11.0.1.0/24", "11.0.2.0/24", "11.0.3.0/24"]
  private_subnets = ["11.0.5.0/24", "11.0.6.0/24", "11.0.7.0/24"]

  tags = {
    Name = "test-vpc-module"
  }

}