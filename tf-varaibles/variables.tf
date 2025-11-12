variable "aws_instance_type" {
    description = "Give the aws instance type you want to use:"
    type = string
    validation {
        condition = var.aws_instance_type == "t2.micro" || var.aws_instance_type == "t3.micro"
        error_message = "Only t2 and t3 micro allowed"
    }
}

# you can also set this value using this command in the terminal
#  export TF_VAR_aws_instance_type=t3.micro --> sets environment variable
# useful for giving senstive data


# variable "root_volume_size" {
#     description = "Give the volume size:"
#     type = number
#     default = 20
# }


# variable "root_volume_type" {
#     description = "Give the root volume type you want to use:"
#     type = string
#     default = "gp2"
#     validation {
#         condition = var.aws_instance_type == "gp2" || var.aws_instance_type == "gp3"
#         error_message = "Only gp2 and gp3 allowed"
#     }
# }

# combining the above 2 into one object


variable "ec2_root_config" {
    type = object({
        v_size = number
        v_type = string
    })

    default = {
        v_size = 20
        v_type = "gp2"
    }
}


variable "additional_tags" {
    type = map(string)
    default = {}
}



# this is the highest priority of all the variables, use this in command line
# terraform plan -var='ec2_root_config={ v_size = 20, v_type = "gp3"}'
