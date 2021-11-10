# create repo
# build enonic docker image
# push enonic docker image to ECR only after first creation

resource "aws_ecr_repository" "main" {
  name = "enonic-xp"
}

resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::636059971062:root",
            "arn:aws:iam::953355806585:root"
          ]
        },
        "Action" : [
          "ecr:ListImages",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories"
        ]
      },
      {
        "Effect" : "Allow",
        "Principal" : { "AWS" : "arn:aws:iam::953355806585:root" },
        "Action" : [
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:PutImage",
          "ecr:BatchDeleteImage"
        ]
      }
    ]
  })
}

output "docker_image" {
  value = aws_ecr_repository.main.repository_url
}