resource "aws_vpc" "terraform-vpc-jenkins" {
    cidr_block = "172.0.0.0/16"
    tags = {
        Name = "terraform-vpc-jenkins"
    }
}


resource "aws_subnet" "terraform-private-subnet-jenkins" {
    cidr_block = "172.0.2.0/24"
    vpc_id = aws_vpc.terraform-vpc-jenkins.id
    tags = {
        Name = "terraform-private-subnet-jenkins"
    }
}


resource "aws_subnet" "terraform-public-subnet-jenkins" {
    cidr_block = "172.0.3.0/24"
    vpc_id = aws_vpc.terraform-vpc-jenkins.id
    tags = {
        Name = "terraform-public-subnet-jenkins"
    }
}


resource "aws_internet_gateway" "terraform-igw-jenkins" {
    vpc_id = aws_vpc.terraform-vpc-jenkins.id
    tags = {
        Name = "terraform-igw-jenkins"
    }
}


resource "aws_route_table" "terraform-public-rt-jenkins" {
    vpc_id = aws_vpc.terraform-vpc-jenkins.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.terraform-igw-jenkins.id
    }
    tags = {
        Name = "terraform-public-rt-jenkins"
    }
}

resource "aws_route_table_association" "terraform-public-rt-association" {
    route_table_id = aws_route_table.terraform-public-rt-jenkins.id
    subnet_id = aws_subnet.terraform-public-subnet-jenkins.id

}