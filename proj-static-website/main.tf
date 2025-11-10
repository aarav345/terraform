
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

# creating s3 bucket
resource "aws_s3_bucket" "mywebapp-bucket" {
    bucket = "mywebapp-test-terraform-bucket-${random_id.rand_id.hex}"
}

# creating s3 bucket public access block and setting all to false
resource "aws_s3_bucket_public_access_block" "example" {
    bucket = aws_s3_bucket.mywebapp-bucket.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

# creating s3 bucket policy which allows public access
resource "aws_s3_bucket_policy" "mywebapp-bucket" {
    bucket = aws_s3_bucket.mywebapp-bucket.id
    policy = jsonencode(
        {
            Version = "2012-10-17",		 	 	 
            Statement = [
                {
                    Sid = "PublicReadGetObject",
                    Effect = "Allow",
                    Principal = "*",
                    Action = [
                        "s3:GetObject"
                    ],
                    Resource = [
                        "arn:aws:s3:::${aws_s3_bucket.mywebapp-bucket.id}/*"
                    ]
                }
            ]
        }
    )
}

# creating s3 bucket website configuration for static website
resource "aws_s3_bucket_website_configuration" "mywebapp" {
    bucket = aws_s3_bucket.mywebapp-bucket.id

    index_document {
        suffix = "index.html"
    }
}


# creating s3 bucket objects and adding content
resource "aws_s3_object" "index" {
    bucket = aws_s3_bucket.mywebapp-bucket.bucket
    source = "./index.html"
    key = "index.html"
    content_type = "text/html"
}


resource "aws_s3_object" "styles" {
    bucket = aws_s3_bucket.mywebapp-bucket.bucket
    source = "./styles.css"
    key = "styles.css"
    content_type = "text/css"
}


# returning website endpoint
output "name" {
    value = aws_s3_bucket_website_configuration.mywebapp.website_endpoint
}