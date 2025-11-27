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



variable "github_repo" {
    description = "GitHub repo HTTPS URL"
    type        = string
    default     = "https://github.com/aarav345/node-aws-pipeline.git"
}


variable "codebuild_buildspec" {
    type    = string
    default = "backend/buildspec.yml"
}

variable "codebuild_log_group_name" {
    type    = string
    default = "codebuild-logs-backend"
}


variable "codebuild_role_name" {
    type    = string
    default = "3-tier-codebuild-role"
}


variable "codedeploy_role_name" {
    type    = string
    default = "3-tier-codedeploy-role"
}


variable "ec2_role_name" {
    type    = string
    default = "3-tier-ec2-role"
}





