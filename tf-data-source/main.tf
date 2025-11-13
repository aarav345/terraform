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

provider "aws" {
    region = "ap-south-1"
}


data "aws_ami" "name" {
    most_recent = true
    owners = [ "amazon" ]
}


data "aws_security_group" "name" { # filtering using tags
    tags = {
        webserver = "http"
    }
}


data "aws_vpc" "name" {
    tags = {
        Name = "project-vpc"
    }
}


data "aws_availability_zones" "name" {
    state = "available"
}


# to get the account details
data "aws_caller_identity" "name" {
    
}

data "aws_region" "name" {
}


# output section


output "region_name" {
    value = data.aws_region.name
}


output "called_info" {
    value = data.aws_caller_identity.name

}



output "aws_zones" {
    value = data.aws_availability_zones.name
}

output "aws_ami" {
    value = data.aws_ami.name.id
}

output "aws_security_group" {
    value = data.aws_security_group.name
}


output "aws_vpc" {
    value = data.aws_vpc.name.id
}


# subnet ID
data "aws_subnet" "name" {
    filter {
        name= "vpc-id"
        values = [data.aws_vpc.name.id]
    }

    tags = {
        Name = "project-subnet-private1-ap-south-1a"
    }
}


resource "aws_instance" "myserver" {
    ami = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    security_groups = [ data.aws_security_group.name.id ]
    subnet_id = data.aws_subnet.name.id

    tags = { # optional
        Name= "SampleServer"
    }
}