


resource "aws_iam_role" "enonic_instance" {
  name = "enonic-instance-${var.environment}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  inline_policy {
    name = "ebs"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "ec2:DescribeVolumes"
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:AttachVolume"
          ],
          "Resource" : [
            "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
            "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "s3"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ],
          "Effect" : "Allow",
          "Resource" : aws_s3_bucket.app_bucket.arn
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:Get*"
          ],
          "Resource" : [
            "${aws_s3_bucket.app_bucket.arn}/*"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "logs"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Effect" : "Allow",
          "Resource" : "${aws_cloudwatch_log_group.main.arn}:*:*"
        }
      ]
    })
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name = "/apps/enonic-xp"

  tags = {
    Environment = var.environment
    Application = "enonic-xp"
  }
}

resource "aws_security_group" "instance" {
  name        = "enonic_instances_sg_${var.environment}"
  description = "Security Group for enonics instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2609
    to_port         = 2609
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "enonic-instance-profile-${var.environment}"
  role        = aws_iam_role.enonic_instance.name
}

resource "aws_launch_configuration" "enonic" {
  image_id             = var.enonic_ami
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  security_groups      = [aws_security_group.instance.id]

  user_data = templatefile(format("%s/userdata/enonic-bootstrap.sh", path.module), {
    ebsRegion   = data.aws_region.current.name,
    ebsGroup    = "enonic-es-volume-${var.environment}",
    dockerImage = var.enonic_docker_image
    s3Bucket    = aws_s3_bucket.app_bucket.id
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "enonic" {
  for_each = var.instances

  name = "enonic-xp-${var.environment}-${each.key}-${each.value}"

  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.enonic.name

  health_check_grace_period = var.grace_period
  health_check_type         = "EC2"
  target_group_arns         = [aws_alb_target_group.group.arn]

  vpc_zone_identifier = [each.value]
  tag {
    key                 = "Name"
    value               = "enonic-xp-${var.environment}-${each.key}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = false
  }
}

