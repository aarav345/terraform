provider "aws" {
    region = "ap-south-1"
}

module "vpc" {
    source = "./module/vpc"

    vpc_config = {
        cidr_block = "10.0.0.0/16"
        name = "my-test-vpc"
    }


    subnet_config = {
        public_subnet-1 = {
            cidr_block = "10.0.4.0/24"
            az = "ap-south-1a"
            public = true
        }

        public_subnet-2 = {
            cidr_block = "10.0.5.0/24"
            az = "ap-south-1b"
            public = true
        }

        private_subnet = {
            cidr_block = "10.0.5.0/24"
            az = "ap-south-1b"
        }
    }
}