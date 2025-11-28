resource "aws_autoscaling_group" "application_tier_asg" {
    name = "application-tier-asg"

    launch_template {
        id      = aws_launch_template.application_tier_lt.id
        version = "$Latest"
    }

    vpc_zone_identifier = [
        aws_subnet.private_subnet_2a.id,
        aws_subnet.private_subnet_2b.id
    ]

    min_size         = 1
    max_size         = 2
    desired_capacity = 1

    # Enable ELB health checks
    health_check_type         = "ELB"
    health_check_grace_period = 600

    force_delete = true

    # Attach to Application Load Balancer target group
    target_group_arns = [aws_lb_target_group.application_tg.arn]

    metrics_granularity = "1Minute"
    enabled_metrics = [
        "GroupMinSize",
        "GroupMaxSize",
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupPendingInstances",
        "GroupTerminatingInstances",
        "GroupTotalInstances"
    ]

    lifecycle {
        create_before_destroy = true
    }

    tag {
        key                 = "Name"
        value               = "${var.project_name}-application-tier-asg"
        propagate_at_launch = true
    }

    depends_on = [
        aws_lb.application_alb,
        aws_lb_target_group.application_tg
    ]
}

# ---- Target Tracking Scaling Policy (CPU) ----
resource "aws_autoscaling_policy" "application_tier_cpu_policy" {
    name                   = "application-tier-cpu-policy"
    autoscaling_group_name = aws_autoscaling_group.application_tier_asg.name
    policy_type            = "TargetTrackingScaling"
    estimated_instance_warmup = 120

    target_tracking_configuration {
        predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
    }
}





# Presentation Tier Auto Scaling Group
resource "aws_autoscaling_group" "presentation_tier_asg" {
    name = "presentation-tier-asg"

    launch_template {
        id      = aws_launch_template.presentation_tier_lt.id
        version = "$Latest"
    }

    vpc_zone_identifier = [
        aws_subnet.private_subnet_1a.id,
        aws_subnet.private_subnet_1b.id
    ]

    min_size         = 1
    max_size         = 2
    desired_capacity = 1

    # Enable ELB health checks
    health_check_type         = "ELB"
    health_check_grace_period = 120

    force_delete = true

    # Attach to presentation Load Balancer target group
    target_group_arns = [aws_lb_target_group.presentation_tg.arn]

    metrics_granularity = "1Minute"
    enabled_metrics = [
        "GroupMinSize",
        "GroupMaxSize",
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupPendingInstances",
        "GroupTerminatingInstances",
        "GroupTotalInstances"
    ]

    lifecycle {
        create_before_destroy = true
    }

    tag {
        key                 = "Name"
        value               = "${var.project_name}-presentation-tier-asg"
        propagate_at_launch = true
    }

    depends_on = [
        aws_lb.presentation_alb,
        aws_lb_target_group.presentation_tg
    ]
}

# ---- Target Tracking Scaling Policy (CPU) ----
resource "aws_autoscaling_policy" "presentation_tier_cpu_policy" {
    name                   = "presentation-tier-cpu-policy"
    autoscaling_group_name = aws_autoscaling_group.presentation_tier_asg.name
    policy_type            = "TargetTrackingScaling"
    estimated_instance_warmup = 120

    target_tracking_configuration {
        predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
    }
}
