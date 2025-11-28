locals {
    codebuild_config_map = {
        frontend = {
            name            = "${var.project_name}-frontend-build"
            buildspec       = "frontend/buildspec.yml"
            cloudwatch_logs = "codebuild-logs-frontend"
            stream_name     = "frontend"
            description     = "Frontend build project"
            repo_url        = "https://github.com/aarav345/node-aws-pipeline.git"

            # NEW
            pipeline_name   = "${var.project_name}-frontend-pipeline"
            asg_name        = "presentation_tier_asg"
            tg_name         = "presentation_tg"
        }

        backend = {
            name            = "${var.project_name}-backend-build"
            buildspec       = "backend/buildspec.yml"
            cloudwatch_logs = "codebuild-logs-backend"
            stream_name     = "backend"
            description     = "Backend build project"
            repo_url        = "https://github.com/aarav345/node-aws-pipeline.git"

            # NEW
            pipeline_name   = "${var.project_name}-backend-pipeline"
            asg_name        = "application_tier_asg"
            tg_name         = "application_tg"
        }
    }
}



resource "aws_codebuild_project" "project_build" {

    for_each = local.codebuild_config_map

    name          = each.value.name
    description   = each.value.description
    build_timeout = 30

    service_role = data.aws_iam_role.codebuild_role.arn

    source {
        type            = "GITHUB"
        location        = each.value.repo_url
        git_clone_depth = 1
        buildspec       = each.value.buildspec
    }

    source_version  = "aws-codepipeline-ec2"

    environment {
        compute_type                = "BUILD_GENERAL1_SMALL"
        type                        = "LINUX_CONTAINER"
        image                       = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
        image_pull_credentials_type = "CODEBUILD"
        privileged_mode             = true
    }

    artifacts {
        type = "NO_ARTIFACTS"
    }

    logs_config {
        cloudwatch_logs {
            group_name  = each.value.cloudwatch_logs
            stream_name = each.value.stream_name
            status      = "ENABLED"
        }
    }
}



resource "aws_codebuild_webhook" "backend_webhook" {

    for_each = aws_codebuild_project.project_build

    project_name = each.value.name

    filter_group {
        filter {
            type    = "EVENT"
            pattern = "PUSH"
        }
    }
}

