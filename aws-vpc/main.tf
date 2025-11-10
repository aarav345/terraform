
# configuring terraform providers
terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "6.20.0"
        }

        random = {
            source = "hashicorp/random"
            version = "3.7.2"
        }
    }
}

# selecting aws region
provider "aws" {
    region = "ap-south-1"
}

# creating resource for random id
resource "random_id" "rand_id" {
    byte_length = 8
}


# creating vpc
resource "aws_vpc" "terraform-vpc" {
    cidr_block = "172.0.0.0/16"
    tags = {
        Name = "terraform-vpc" 
    }
}


resource "aws_subnet" "terraform-private-subnet" {
    cidr_block = "172.0.2.0/24"
    vpc_id = aws_vpc.terraform-vpc.id
    tags = {
        Name = "terraform-private-subnet"
    }
}


resource "aws_subnet" "terraform-public-subnet" {
    cidr_block = "172.0.1.0/24"
    vpc_id = aws_vpc.terraform-vpc.id
    tags = {
        Name = "terraform-public-subnet"
    }
}


resource "aws_internet_gateway" "terraform-igw" {
    vpc_id = aws_vpc.terraform-vpc.id
    tags = {
        Name = "terraform-igw"
    }
}


resource "aws_route_table" "terraform-public-rt" {
    vpc_id = aws_vpc.terraform-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.terraform-igw.id
    }
}


resource "aws_route_table_association" "terraform-public-rt-association" {
    route_table_id = aws_route_table.terraform-public-rt.id
    subnet_id = aws_subnet.terraform-public-subnet.id
}


resource "aws_instance" "myserver" {
    ami = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"

    tags = { # optional
        Name= "terraform-ec2-vpc-test"
    }

    subnet_id = aws_subnet.terraform-public-subnet.id
}
