
resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "${var.project_name}-ec2-instance-profile"
    role = data.aws_iam_role.ec2_role.name
}


# Bastion host
resource "aws_instance" "bastion_host" {
    ami                    = var.ec2_config_map["ec2"].ami
    instance_type          = var.ec2_config_map["ec2"].instance_type

    subnet_id              = aws_subnet.public_subnet_1a.id
    key_name               = aws_key_pair.terraform_key.key_name

    vpc_security_group_ids = [aws_security_group.bastion_sg.id]

    associate_public_ip_address = true

    tags = {
        Name = "${var.project_name}-bastion-host"
    }
}




# ------------------------------
# Application Tier Launch Template
# ------------------------------

resource "aws_launch_template" "application_tier_lt" {
    name_prefix   = "${var.project_name}-application-tier-lt"
    description   = "Launch Template for Application Tier"
    
    update_default_version = true

    # Auto scaling guidance
    tag_specifications {
        resource_type = "instance"
        tags = {
            "AutoScalingGroup" = "true"
        }
    }

    # AMI & Instance Type from variable map
    image_id      = var.ec2_config_map["ec2"].ami
    instance_type = var.ec2_config_map["ec2"].instance_type

    key_name = aws_key_pair.terraform_key.key_name

    # Security Groups
    vpc_security_group_ids = [
        aws_security_group.application_ec2_sg.id
    ]

    # IAM Instance Profile (already created in AWS console)
    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_instance_profile.name
    }

    # Load user data from file (Base64 encoding automatically handled)
    user_data = filebase64("${path.module}/scripts/applicationTier.sh")

    lifecycle {
        create_before_destroy = true
    }

    tags = {
        Name = "${var.project_name}-application-tier-lt"
    }
}




# ------------------------------
# presentation Tier Launch Template
# ------------------------------

resource "aws_launch_template" "presentation_tier_lt" {
    name_prefix   = "${var.project_name}-presentation-tier-lt"
    description   = "Launch Template for presentation Tier"

    update_default_version = true

    tag_specifications {
        resource_type = "instance"
        tags = {
        "AutoScalingGroup" = "true"
        }
    }

    image_id      = var.ec2_config_map["ec2"].ami
    instance_type = var.ec2_config_map["ec2"].instance_type
    key_name      = aws_key_pair.terraform_key.key_name

    vpc_security_group_ids = [aws_security_group.presentation_ec2_sg.id]

    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_instance_profile.name
    }

    # Pass ALB DNS dynamically
    user_data = base64encode(
        templatefile("${path.module}/scripts/presentationTier.sh.tpl", {
            APP_TIER_ALB_URL = aws_lb.application_alb.dns_name
            NGINX_CONF       = "/etc/nginx/nginx.conf"
            SERVER_NAME      = "aaravpradhan.online www.aaravpradhan.online"
            REGION           = "ap-south-1"
        })
        )

    lifecycle {
        create_before_destroy = true
    }

    tags = {
        Name = "${var.project_name}-presentation-tier-lt"
    }

    depends_on = [aws_lb.application_alb]
}
