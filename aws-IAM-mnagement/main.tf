
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
    users = yamldecode(file("users.yaml")).users
}


output "user_data" {
    value = local.users[*].username
}


# creates users
resource "aws_iam_user" "users" {
    for_each = toset(local.users[*].username)
    name = each.value
}


# password creation
resource "aws_iam_user_login_profile" "profile" {
    for_each = aws_iam_user.users
    user = each.value.name
    password_length = 12

    # does not repeatedly create password again and again when terraform is run
    lifecycle {
        ignore_changes = [
        password_length,
        password_reset_required,
        pgp_key,
        ]
    }
}