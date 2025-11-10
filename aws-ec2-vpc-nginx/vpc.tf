# creating vpc
resource "aws_vpc" "terraform-vpc" {
    cidr_block = "172.0.0.0/16"
    tags = {
        Name = "terraform-vpc" 
    }
}


resource "aws_subnet" "terraform-private-subnet" {
    cidr_block = "172.0.2.0/24"
    vpc_id = aws_vpc.terraform-vpc.id
    tags = {
        Name = "terraform-private-subnet"
    }
}


resource "aws_subnet" "terraform-public-subnet" {
    cidr_block = "172.0.1.0/24"
    vpc_id = aws_vpc.terraform-vpc.id
    tags = {
        Name = "terraform-public-subnet"
    }
}


resource "aws_internet_gateway" "terraform-igw" {
    vpc_id = aws_vpc.terraform-vpc.id
    tags = {
        Name = "terraform-igw"
    }
}


resource "aws_route_table" "terraform-public-rt" {
    vpc_id = aws_vpc.terraform-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.terraform-igw.id
    }
}


resource "aws_route_table_association" "terraform-public-rt-association" {
    route_table_id = aws_route_table.terraform-public-rt.id
    subnet_id = aws_subnet.terraform-public-subnet.id
}