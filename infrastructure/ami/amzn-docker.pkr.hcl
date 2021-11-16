packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2" # "
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amzn2" {
  assume_role {
      role_arn     = "arn:aws:iam::953355806585:role/cicd/ma-fulladmin"
      session_name = "packer"
  }

  ami_users     = ["636059971062"]
  ami_name      = "amzn2-ami-hvm-with-docker-{{isotime | clean_resource_name}}"
  instance_type = "t2.micro"
  region        = "eu-central-1"
  source_ami_filter {
    filters = {
      name                = "amazon/amzn2-ami-hvm-*-x86_64-gp2" # */
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
      "amazon-linux-extras install docker",
      "service docker start",
      "usermod -a -G docker ec2-user",
      "chkconfig docker on"
    ]
  }
}