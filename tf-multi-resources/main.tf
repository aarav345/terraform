
terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "6.20.0"
        }
    }
}


provider "aws" {
    region = "ap-south-1"
}


locals {
    project = "project-01"
}

resource "aws_vpc" "my-vpc" {
    cidr_block = "172.0.0.0/16"
    tags = {
        Name = "${local.project}-vpc"
    }
}

resource "aws_subnet" "main" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "172.0.${count.index}.0/24"
    count = 2 # creating 2 subnets
    tags = {
        Name = "${local.project}-subnet-${count.index + 1}" # index starts from 0
    }
}



# creating 4 ec2 instances in 2 subnets equally
# resource "aws_instance" "main" {
#     ami = "ami-02b8269d5e85954ef"
#     instance_type = "t3.micro"
#     count = 4

#     subnet_id = element(aws_subnet.main[*].id, count.index % length(aws_subnet.main))

#     tags = {
#         Name = "${local.project}-ec2-${count.index + 1}"
#     }
# }

# creating 2 ec2 instances in ubuntu and amazon each
# resource "aws_instance" "main" {
#     count = length(var.ec2_config)
#     ami = var.ec2_config[count.index].ami
#     instance_type = var.ec2_config[count.index].instance_type

#     subnet_id = element(aws_subnet.main[*].id, count.index % length(aws_subnet.main))

#     tags = {
#         Name = "${local.project}-ec2-${count.index + 1}"
#     }
# }



// now using for_each instead of count
resource "aws_instance" "main" {
    for_each = var.ec2_map # runs for each key value pair

    ami = each.value.ami
    instance_type = each.value.instance_type

    subnet_id = element(aws_subnet.main[*].id, index(keys(var.ec2_map), each.key) % length(aws_subnet.main))

    tags = {
        Name = "${local.project}-ec2-${each.key}"
    }
}


output "aws_subnet_id" {
    value = aws_subnet.main[0].id
}
