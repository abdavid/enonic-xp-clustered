#!/bin/bash
set -e

_scanDirs=$@
_scriptDir="$(dirname $(realpath $0))"

tfApply() {
    _tmpDir=$(mktemp -d)
    workDir=$1
    echo "Fetching artifact for $workDir..."
    aws --region ${TF_ARTIFACTS_REGION:-eu-west-1} s3 cp s3://$TF_ARTIFACTS_S3/$workDir/plans/${TRAVIS_COMMIT}.out $_tmpDir/tf.out
    echo "Applying for $workDir"
    $_scriptDir/terraform.sh init
    $_scriptDir/terraform.sh apply -auto-approve -input=false $_tmpDir/tf.out
    rm -r $_tmpDir
}

for dir in $_scanDirs; do
    echo "---------------"
    echo "Running apply for $dir..."
    echo ""
    pushd $dir
    # Run tests
    tfApply $dir
    popd
    echo ""
done