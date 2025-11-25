resource "aws_ssm_parameter" "db_user" {
    name  = "/nodeapp/db/user"
    type  = "String"
    value = var.db_config.db_user
}

resource "aws_ssm_parameter" "db_password" {
    name  = "/nodeapp/db/password"
    type  = "SecureString"
    value = var.db_config.db_password
}

resource "aws_ssm_parameter" "db_host" {
    name  = "/nodeapp/db/hostname"
    type  = "String"
    value = aws_db_instance.dev_mysql.endpoint
}

resource "aws_ssm_parameter" "db_port" {
    name  = "/nodeapp/db/port"
    type  = "String"
    value = var.db_config.db_port
}

resource "aws_ssm_parameter" "db_name" {
    name  = "/nodeapp/db/name"
    type  = "String"
    value = var.db_config.db_name
}
