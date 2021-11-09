#!/bin/bash
ecr=$1
dir=$2
commit=$(git rev-parse HEAD)
dockerImg=${ecr}:${commit}


aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecr}
docker build -t ${dockerImg} $dir
docker push ${dockerImg}

echo ${dockerImg} >> current-docker-image.txt