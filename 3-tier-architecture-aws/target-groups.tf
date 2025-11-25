# ---- Application Tier Target Group ----
resource "aws_lb_target_group" "application_tg" {
    name        = "application-tier-tg"
    port        = 3200
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = aws_vpc.three-tier-architecture-terraform.id

    health_check {
        enabled             = true
        interval            = 30
        path                = "/health"
        matcher             = "200-399"
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        protocol            = "HTTP"
    }

    tags = {
        Name = "application-tier-tg"
    }
}





# ---- presentation Tier Target Group ----
resource "aws_lb_target_group" "presentation_tg" {
    name        = "presentation-tier-tg"
    port        = 80
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = aws_vpc.three-tier-architecture-terraform.id

    health_check {
        enabled             = true
        interval            = 30
        path                = "/health"
        matcher             = "200-399"
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        protocol            = "HTTP"
    }

    tags = {
        Name = "presentation-tier-tg"
    }
}
