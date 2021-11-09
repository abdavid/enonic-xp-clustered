# create repo
# build enonic docker image
# push enonic docker image to ECR only after first creation

resource "aws_ecr_repository" "main" {
  name = var.app_name
}

variable "docker_dir" {
  type = string
}

resource "null_resource" "docker_image" {
  provisioner "local-exec" {
    command = "${path.module}/bin/build_push.sh ${aws_ecr_repository.main.repository_url} ${var.docker_dir}"
  }
}

data "local_file" "docker_image" {
  depends_on = [null_resource.docker_image]
  filename   = "${path.cwd}/current-docker-image.txt"
}