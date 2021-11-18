packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2" # "
      source  = "github.com/hashicorp/amazon"
    }
    amazon-ami-management = {
      version = "= 1.2.0"
      source  = "github.com/wata727/amazon-ami-management"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "assume_role" {
  type = string
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "CID" {
  type = string
}

source "amazon-ebs" "amzn2" {
  assume_role {
    role_arn     = var.assume_role
    session_name = "packer"
  }

  ami_users     = ["636059971062"]
  ami_name      = "amzn2-ami-hvm-with-docker-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["137112412989"]
  }
  ssh_username = "ec2-user"

  temporary_iam_instance_profile_policy_document {
    Statement {
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::sch-cbt-binaries/edr/*"
    }
    Version = "2012-10-17"
}

  tags = {
    Amazon_AMI_Management_Identifier = "amzn2-with-docker-ssm"
  }
}

build {
  name = "amzn2-ami-hvm-with-docker"
  sources = [
    "source.amazon-ebs.amzn2"
  ]

  provisioner "shell" {
    inline = [
      "echo Installing Docker",
      "sudo amazon-linux-extras install -y epel docker python3.8",
      "sudo yum install -y amazon-ssm-agent s3fs-fuse awscli",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo chkconfig docker on",
      "sudo systemctl enable amazon-ssm-agent",
      "aws s3 cp s3://sch-cbt-binaries/edr/falcon-sensor-6.28.0-12504.amzn2.x86_64.rpm /tmp/falcon.rpm",
      "sudo rpm -ivh /tmp/falcon.rpm",
      "rm /tmp/falcon.rpm",
      "sudo /opt/CrowdStrike/falconctl -s --tags=\"cbt,awsCloud\" --cid=${var.CID}",
      "sudo systemctl enable falcon-sensor"
    ]
  }

  post-processor "amazon-ami-management" {
    regions       = [var.region]
    identifier    = "amzn2-with-docker-ssm"
    keep_releases = 3
    assume_role {
      role_arn     = var.assume_role
      session_name = "packer-cleaner"
    }
  }
}