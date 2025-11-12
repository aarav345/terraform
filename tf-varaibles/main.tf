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




resource "aws_instance" "myserver" {
    ami = "ami-02b8269d5e85954ef"
    instance_type = var.aws_instance_type

    root_block_device {
        delete_on_termination = true
        volume_size = var.ec2_root_config.v_size
        volume_type = var.ec2_root_config.v_type
    }

    tags = merge(var.additional_tags, {
        Name= "SampleServer"
    })
}