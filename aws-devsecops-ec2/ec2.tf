locals {
    project = "project-devsec-cicd"
}

resource "aws_instance" "terraform-jenkins-instances" {
    for_each = var.ec2_config_map

    ami = each.value.ami
    instance_type = each.value.instance_type

    subnet_id = aws_subnet.terraform-public-subnet-jenkins.id
    vpc_security_group_ids = [ aws_security_group.terraform-sg-jenkins.id ]
    associate_public_ip_address = true
    key_name = aws_key_pair.terraform_key.key_name

    root_block_device {
        volume_size = 15
        volume_type = "gp3"
        delete_on_termination = true
        tags = {
            Name = "${local.project}-ec2-${each.key}-root"
        }
    }

    user_data = each.key == "Jenkins" ? file("${path.module}/scripts/jenkins.sh") : null


    tags = { 
        Name = "${local.project}-ec2-${each.key}"
    }
}