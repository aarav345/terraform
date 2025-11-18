
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

    user_role_pair = flatten([ for user in local.users: [for role in user.roles: {
        username = user.username
        role = role
    }]]) # makes list of lists into a single list
}


output "user_data" {
    value = local.user_role_pair
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



resource "aws_iam_user_policy_attachment" "name" { 
    for_each = {
        for pair in local.user_role_pair :
        "${pair.username}-${pair.role}" => pair
    }

    user = aws_iam_user.users[each.value.username].name
    policy_arn = "arn:aws:iam::aws:policy/${each.value.role}"
}