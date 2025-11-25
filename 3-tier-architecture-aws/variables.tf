variable "project_name" {
    description = "Base name for all resources in this 3-tier architecture"
    type        = string
    default     = "three-tier-architecture"
}

variable "ec2_config_map" {
    type = map(object({
        ami = string
        instance_type = string 
    }))
}


variable "db_username" {
    default = "admin"
}

variable "db_password" {
    default = "Aaswon1234"
    sensitive = true
}


variable "db_config" {
    type = object({
        db_user = string
        db_password = string
        sensitive = bool
        db_port = string
        db_name = string
    })
}
