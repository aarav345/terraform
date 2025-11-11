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

output "aws_ami" {
    value = data.aws_ami.name.id
}

output "aws_security_group" {
    value = data.aws_security_group.name
}


output "aws_vpc" {
    value = data.aws_vpc.name.id
}



resource "aws_instance" "myserver" {
    ami = data.aws_ami.name.id
    instance_type = "t3.micro"

    tags = { # optional
        Name= "SampleServer"
    }
}