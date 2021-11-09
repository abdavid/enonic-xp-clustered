#!/bin/bash
dir=$1
ecr=$2
tag=$3
dockerImg=${ecr}:${tag}


aws ecr get-login-password --region ${AWS_REGION:=eu-central-1} | docker login --username AWS --password-stdin ${ecr}
docker build -t ${dockerImg} $dir
docker push ${dockerImg}
