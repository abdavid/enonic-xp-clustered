

resource "aws_security_group" "alb" {
  name        = "enonic_alb_sg_${var.environment}"
  description = "Security Group for enonics LB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "enonic-alb-${var.environment}-sg"
  }
}

resource "aws_alb" "alb" {
  name            = "enonic-${var.environment}-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = var.lb_subnets
  tags = {
    Name = "enonic-${var.environment}-alb"
  }
}

resource "aws_alb_target_group" "group" {
  name     = "enonic-${var.environment}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  stickiness {
    type = "lb_cookie"
  }
  health_check {
    path = var.healthcheck_path
    port = var.healthcheck_port
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.enonic.arn
  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}
