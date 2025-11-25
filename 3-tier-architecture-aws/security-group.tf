# ---- Bastion Host Security Group ----
resource "aws_security_group" "bastion_sg" {
    name        = "bastion-host-sg"
    description = "Security group for bastion host, allowing SSH access"
    vpc_id      = aws_vpc.three-tier-architecture-terraform.id

    # Inbound rules
    ingress {
        description      = "Allow SSH from anywhere"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]   # Change to your IP range for production
    }

    # Outbound rules
    egress {
        description      = "Allow all outbound traffic"
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "bastion-host-sg"
    }
}


# ---- ALB Security Group (Presentation Tier)----
resource "aws_security_group" "presentation_alb_sg" {
    name        = "presentation-tier-alb-sg"
    description = "Security group for the ALB (presentation tier) allowing HTTP access"
    vpc_id      = aws_vpc.three-tier-architecture-terraform.id

    ingress {
        description      = "Allow HTTP from anywhere"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }


    egress {
        description      = "Allow all outbound traffic"
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "presentation-tier-alb-sg"
    }
}



# ---- EC2 Security Group (Presentation Tier) ----
resource "aws_security_group" "presentation_ec2_sg" {
    name        = "presentation-tier-ec2-sg"
    description = "Security group for presentation tier EC2 instances"
    vpc_id      = aws_vpc.three-tier-architecture-terraform.id

    # Ingress: HTTP from ALB only
    ingress {
        description            = "Allow HTTP from ALB"
        from_port              = 80
        to_port                = 80
        protocol               = "tcp"
        security_groups        = [aws_security_group.presentation_alb_sg.id]
    }

    # Ingress: SSH from Bastion Host only
    ingress {
        description            = "Allow SSH from Bastion Host"
        from_port              = 22
        to_port                = 22
        protocol               = "tcp"
        security_groups        = [aws_security_group.bastion_sg.id]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "presentation-tier-ec2-sg"
    }
}



# ---- ALB Security Group (application Tier)----
resource "aws_security_group" "application_alb_sg" {
    name        = "application-tier-alb-sg"
    description = "Security group for the ALB (application tier) allowing HTTP access"
    vpc_id      = aws_vpc.three-tier-architecture-terraform.id

    ingress {
        description      = "Allow HTTP from anywhere"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        security_groups      = [aws_security_group.presentation_ec2_sg.id]
    }


    egress {
        description      = "Allow all outbound traffic"
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "application-tier-alb-sg"
    }
}



# ---- EC2 Security Group (Application Tier) ----
resource "aws_security_group" "application_ec2_sg" {
    name        = "application-tier-ec2-sg"
    description = "Security group for application tier EC2 instances"
    vpc_id      = aws_vpc.three-tier-architecture-terraform.id


    # Ingress: HTTP from ALB only
    ingress {
        description            = "Allow port 3200 from ALB"
        from_port              = 3200
        to_port                = 3200
        protocol               = "tcp"
        security_groups        = [aws_security_group.application_alb_sg.id]
    }

    # Ingress: SSH from Bastion Host only
    ingress {
        description            = "Allow SSH from Bastion Host"
        from_port              = 22
        to_port                = 22
        protocol               = "tcp"
        security_groups        = [aws_security_group.bastion_sg.id]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "application-tier-ec2-sg"
    }
}



# ---- Data Tier Security Group (MySQL/Aurora) ----
resource "aws_security_group" "data_tier_sg" {
    name        = "data-tier-sg"
    description = "Security group for data tier (MySQL/Aurora), allowing traffic from application tier EC2 and Bastion Host"
    vpc_id      = aws_vpc.three-tier-architecture-terraform.id

    # Ingress: MySQL/Aurora from Application Tier EC2
    ingress {
        description     = "Allow MySQL from application EC2"
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        security_groups = [aws_security_group.application_ec2_sg.id]
    }

    # Ingress: SSH from Bastion Host (for admin)
    ingress {
        description     = "Allow MySQL/Aurora from Bastion Host"
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        security_groups = [aws_security_group.bastion_sg.id]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "data-tier-sg"
    }
}
