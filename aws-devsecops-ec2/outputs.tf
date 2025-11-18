output "aws_instance_public_ip" {
    description = " Public ip of all three servers"
    value = values(aws_instance.terraform-jenkins-instances)[*].public_ip
}

output "aws_vpc_id" {
    description = " VPC ID"
    value = aws_vpc.terraform-vpc-jenkins.id
}

output "aws_public_subnet_id" {
    value = aws_subnet.terraform-public-subnet-jenkins.id
}