
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
    region = var.region
}

resource "random_id" "rand_id" {
    byte_length = 8
}


resource "aws_s3_bucket" "demo-bucket" {
    bucket = "demo-test-terraform-bucket-${random_id.rand_id.hex}"
}


resource "aws_s3_object" "bucket-data" {
    bucket = aws_s3_bucket.demo-bucket.bucket
    source = "./myfile.txt"
    key = "mydata.txt"
}