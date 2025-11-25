# ---- Application Tier ALB ----
resource "aws_lb" "application_alb" {
    name               = "application-tier-alb"
    internal           = true                # Internal ALB
    load_balancer_type = "application"
    security_groups    = [aws_security_group.application_alb_sg.id]
    subnets            = [
        aws_subnet.private_subnet_2a.id,
        aws_subnet.private_subnet_2b.id
    ]

    enable_deletion_protection = false

    tags = {
        Name = "${var.project_name}-application-tier-alb"
    }
}

    # ---- Application Tier ALB Listener ----
    resource "aws_lb_listener" "application_alb_listener" {
    load_balancer_arn = aws_lb.application_alb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.application_tg.arn
    }

    depends_on = [ aws_lb_target_group.application_tg ]
}




# ---- Presentation Tier ALB ----
resource "aws_lb" "presentation_alb" {
    name               = "presentation-tier-alb"
    internal           = false                # Internal ALB
    load_balancer_type = "application"
    security_groups    = [aws_security_group.presentation_alb_sg.id]
    subnets            = [
        aws_subnet.public_subnet_1a.id,
        aws_subnet.public_subnet_1b.id
    ]

    enable_deletion_protection = false

    tags = {
        Name = "${var.project_name}-presentation-tier-alb"
    }

}

    # ---- presentation Tier ALB Listener ----
    resource "aws_lb_listener" "presentation_alb_listener" {
    load_balancer_arn = aws_lb.presentation_alb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.presentation_tg.arn
    }

    depends_on = [ aws_lb_target_group.presentation_tg ]
}

