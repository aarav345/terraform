resource "aws_codepipeline" "backend_pipeline" {

    for_each = aws_codebuild_project.project_build

    name           = each.key == "backend" ? "${var.project_name}-backend-pipeline" : "${var.project_name}-frontend-pipeline"
    pipeline_type  = "V2"
    execution_mode = "QUEUED"
    role_arn       = data.aws_iam_role.codepipeline_role.arn

    artifact_store {
        type     = "S3"
        location = aws_s3_bucket.simple_bucket.id
    }

    ## ---------------------- SOURCE STAGE -----------------------
    stage {
        name = "Source"

        action {
            name             = "GitHub_Source"
            category         = "Source"
            owner            = "AWS"
            provider         = "CodeStarSourceConnection"
            version          = "1"

            output_artifacts = ["source_output"]

            configuration = {
                ConnectionArn        = data.aws_codestarconnections_connection.github_connection.arn
                FullRepositoryId     = "aarav345/node-aws-pipeline"
                BranchName           = "aws-codepipeline-ec2"
                DetectChanges        = "true"
                OutputArtifactFormat = "CODE_ZIP"  # Optional but recommended
            }
        }
    }

    ## ---------------------- BUILD STAGE -----------------------
    stage {
        name = "Build"

        action {
            name             = "CodeBuild_Project"
            category         = "Build"
            owner            = "AWS"
            provider         = "CodeBuild"
            version          = "1"

            input_artifacts  = ["source_output"]
            output_artifacts = ["build_output"]

            configuration = {
                ProjectName = each.value.name
            }
        }
    }

    ## ---------------------- DEPLOY STAGE -----------------------
    stage {
        name = "Deploy"

        action {
            name            = "CodeDeploy"
            category        = "Deploy"
            owner           = "AWS"
            provider        = "CodeDeploy"
            version         = "1"
            input_artifacts = ["build_output"]

            configuration = {
                ApplicationName     = each.key == "backend" ? aws_codedeploy_app.backend_deploy.name : aws_codedeploy_app.frontend_deploy.name
                DeploymentGroupName = each.key == "backend" ? aws_codedeploy_deployment_group.backend_deployment_group.deployment_group_name : aws_codedeploy_deployment_group.frontend_deployment_group.deployment_group_name
            }
        }
    }
}

