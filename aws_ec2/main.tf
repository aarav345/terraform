
terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "6.20.0"
        }
    }
}


provider "aws" {
    region = var.region
}


resource "aws_instance" "example" {
    ami = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"

    tags = { # optional
        Name= "SampleServer"
    }
}

