
variable "region" {
    description = "value"
    default = "ap-south-1"
}


terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "6.20.0"
        }
    }

    backend "s3" {
        bucket = "demo-test-terraform-bucket-8741772f60085548"
        key = "backend.tfstate"
        region = "ap-south-1"
    }
}


provider "aws" {
    region = var.region
}


resource "aws_instance" "myserver" {
    ami = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"

    tags = { # optional
        Name= "SampleServer"
    }
}

