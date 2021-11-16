packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2" # "
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "assume_role" {
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
  region        = "eu-central-1"
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
}

build {
  name = "amzn2-ami-hvm-with-docker"
  sources = [
    "source.amazon-ebs.amzn2"
  ]

  provisioner "shell" {
    inline = [
      "echo Installing Docker",
      "sudo amazon-linux-extras install docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo chkconfig docker on"
    ]
  }
}