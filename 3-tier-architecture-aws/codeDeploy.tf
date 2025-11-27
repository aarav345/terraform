resource "aws_codedeploy_app" "backend_deploy" {
    name = "${var.project_name}-backend-deploy"
    compute_platform = "Server" # EC2/on-premises
}


# Code Deployment Group
resource "aws_codedeploy_deployment_group" "backend_deployment_group" {
    app_name = aws_codedeploy_app.backend_deploy.name
    deployment_group_name = "${var.project_name}-backend-deployment-group"
    service_role_arn = data.aws_iam_role.codedeploy_role.arn


    deployment_config_name = "CodeDeployDefault.AllAtOnce" # In-place deployment

    # Associate automatic scaling group
    autoscaling_groups = [
        aws_autoscaling_group.application_tier_asg.name
    ]

    # Load balancer settings
    load_balancer_info {
        target_group_info {
            name = aws_lb_target_group.application_tg.name
        }
    }

}