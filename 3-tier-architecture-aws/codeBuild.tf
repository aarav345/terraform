locals {
    codebuild_project_name = "${var.project_name}-backend-build"
}


resource "aws_codebuild_project" "backend_build" {
    name          = local.codebuild_project_name
    description   = "Backend build project"
    build_timeout = 30

    service_role = data.aws_iam_role.codebuild_role.arn

    source {
        type            = "GITHUB"
        location        = "https://github.com/aarav345/node-aws-pipeline.git"
        git_clone_depth = 1
        buildspec       = "backend/buildspec.yml"
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
            group_name  = "codebuild-logs-backend"
            stream_name = "backend"
            status      = "ENABLED"
        }
    }
}



resource "aws_codebuild_webhook" "backend_webhook" {
    project_name = aws_codebuild_project.backend_build.name

    filter_group {
        filter {
            type    = "EVENT"
            pattern = "PUSH"
        }
    }
}

