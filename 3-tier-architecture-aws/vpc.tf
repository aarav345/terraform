resource "aws_vpc" "three-tier-architecture-terraform" {
    cidr_block           = "172.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = "three-tier-architecture-terraform"
    }
}

# Get Availability Zones
data "aws_availability_zones" "available" {}


# ---- Public Subnets (2 AZs) ----
resource "aws_subnet" "public_subnet_1a" {
    vpc_id                  = aws_vpc.three-tier-architecture-terraform.id
    cidr_block              = "172.0.1.0/24"
    availability_zone       = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.project_name}-PublicSubnet1A"
    }
}

resource "aws_subnet" "public_subnet_1b" {
    vpc_id                  = aws_vpc.three-tier-architecture-terraform.id
    cidr_block              = "172.0.2.0/24"
    availability_zone       = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.project_name}-PublicSubnet1B"
    }
}

# ---- Private Subnets (2 in each AZ = 6 total) ----

# AZ-A
resource "aws_subnet" "private_subnet_1a" {
    vpc_id            = aws_vpc.three-tier-architecture-terraform.id
    cidr_block        = "172.0.11.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        Name = "${var.project_name}-PrivateSubnet1A"
    }
}

resource "aws_subnet" "private_subnet_1b" {
    vpc_id            = aws_vpc.three-tier-architecture-terraform.id
    cidr_block        = "172.0.12.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]

    tags = {
        Name = "${var.project_name}-PrivateSubnet1B"
    }
}



resource "aws_subnet" "private_subnet_2a" {
    vpc_id            = aws_vpc.three-tier-architecture-terraform.id
    cidr_block        = "172.0.13.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        Name = "${var.project_name}-PrivateSubnet2A"
    }
}

resource "aws_subnet" "private_subnet_2b" {
    vpc_id            = aws_vpc.three-tier-architecture-terraform.id
    cidr_block        = "172.0.14.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]

    tags = {
        Name = "${var.project_name}-PrivateSubnet2B"
    }
}


resource "aws_subnet" "private_subnet_3a" {
    vpc_id            = aws_vpc.three-tier-architecture-terraform.id
    cidr_block        = "172.0.15.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        Name = "${var.project_name}-PrivateSubnet3A"
    }
}

resource "aws_subnet" "private_subnet_3b" {
    vpc_id            = aws_vpc.three-tier-architecture-terraform.id
    cidr_block        = "172.0.16.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]

    tags = {
        Name = "${var.project_name}-PrivateSubnet3B"
    }
}


# Internet Gateway
resource "aws_internet_gateway" "three-tier-igw" {
    vpc_id = aws_vpc.three-tier-architecture-terraform.id

    tags = {
        Name = "${var.project_name}-igw"
    }
}


# ---- Elastic IP for NAT Gateway ----
resource "aws_eip" "nat_gw_eip" {
    domain = "vpc"

    tags = {
        Name = "${var.project_name}-nat-eip"
    }
}

# ---- NAT Gateway ----
resource "aws_nat_gateway" "nat_gateway" {
    allocation_id = aws_eip.nat_gw_eip.id
    subnet_id     = aws_subnet.public_subnet_1a.id   # PublicSubnet1A
    connectivity_type = "public"                     # default for NAT GW

    tags = {
        Name = "${var.project_name}-nat-gateway"
    }
}



# ---- Public Route Table ----
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.three-tier-architecture-terraform.id

    tags = {
        Name = "${var.project_name}-public-rt"
    }
}

# ---- Route: 0.0.0.0/0 → Internet Gateway ----
resource "aws_route" "public_internet_access" {
    route_table_id         = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.three-tier-igw.id
}

# ---- Associate Public Subnet 1A ----
resource "aws_route_table_association" "public_subnet_1a_association" {
    subnet_id      = aws_subnet.public_subnet_1a.id
    route_table_id = aws_route_table.public_rt.id
}


# ---- Associate Public Subnet 1B ----
resource "aws_route_table_association" "public_subnet_1b_association" {
    subnet_id      = aws_subnet.public_subnet_1b.id
    route_table_id = aws_route_table.public_rt.id
}




# ---- Private Route Table ----
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.three-tier-architecture-terraform.id

    tags = {
        Name = "${var.project_name}-private-rt"
    }
}

# ---- Route: 0.0.0.0/0 → NAT Gateway ----
resource "aws_route" "private_nat_route" {
    route_table_id         = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# ---- Associate All Private Subnets ----

# AZ-A Subnets
resource "aws_route_table_association" "private_subnet_1a_association" {
    subnet_id      = aws_subnet.private_subnet_1a.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2a_association" {
    subnet_id      = aws_subnet.private_subnet_2a.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_3a_association" {
    subnet_id      = aws_subnet.private_subnet_3a.id
    route_table_id = aws_route_table.private_rt.id
}

# AZ-B Subnets
resource "aws_route_table_association" "private_subnet_1b_association" {
    subnet_id      = aws_subnet.private_subnet_1b.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2b_association" {
    subnet_id      = aws_subnet.private_subnet_2b.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_3b_association" {
    subnet_id      = aws_subnet.private_subnet_3b.id
    route_table_id = aws_route_table.private_rt.id
}