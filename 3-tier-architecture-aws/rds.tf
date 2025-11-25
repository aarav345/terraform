# ---- RDS DB Subnet Group ----
resource "aws_db_subnet_group" "db_subnet_group" {
    name       = "${var.project_name}-db-subnet-group"
    description = "DB subnet group for RDS in private subnets"

    subnet_ids = [
        aws_subnet.private_subnet_3a.id,
        aws_subnet.private_subnet_3b.id
    ]

    tags = {
        Name = "${var.project_name}-db-subnet-group"
    }
}



resource "aws_db_instance" "dev_mysql" {
    identifier              = "dev-db-instance"
    engine                  = "mysql"
    engine_version          = "8.0"
    instance_class          = "db.t3.micro"     # You can upgrade later
    allocated_storage       = 200

    # Credentials
    username                = var.db_username
    password                = var.db_password

    # Networking
    db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
    vpc_security_group_ids  = [aws_security_group.data_tier_sg.id]
    publicly_accessible     = false

    # Multi-AZ deployment
    multi_az                = true

    # Additional settings
    skip_final_snapshot     = true
    storage_type            = "gp3"

    tags = {
        Name = "${var.project_name}-dev-db-instance"
        Environment = "dev"
    }
}
