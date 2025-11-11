
resource "aws_instance" "nginxserver" {
    ami = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.terraform-public-subnet.id
    vpc_security_group_ids = [ aws_security_group.nginx-sg.id]
    associate_public_ip_address = true
    key_name = aws_key_pair.terraform_key.key_name


    user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    EOF

    tags = { 
        Name= "nginx-terraform-ec2-vpc-test"
    }

}
