data "aws_iam_role" "codebuild_role" {
    name = var.codebuild_role_name
}


data "aws_iam_role" "codedeploy_role" {
    name = var.codedeploy_role_name
}


data "aws_iam_role" "ec2_role" {
    name = var.ec2_role_name
}


data "aws_iam_role" "codepipeline_role" {
    name = var.codepipeline_role_name
}


data "aws_codestarconnections_connection" "github_connection" {
    name = "github"
}