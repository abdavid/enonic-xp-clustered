#!/bin/bash
set -e

_scanDirs=$@
_scriptDir="$(dirname $(realpath $0))"


tfPlan() {
    _tmpDir=$(mktemp -d)
    workDir=$1
    $_scriptDir/terraform.sh init
    $_scriptDir/terraform.sh plan -out $_tmpDir/tf.out

    [[ $TRAVIS_EVENT_TYPE == "pull_request" ]] && { echo "Skipping plan upload due to the PR"; rm -r $_tmpDir; return; }
    echo "Pushing plan to S3..."
    aws --region ${TF_ARTIFACTS_REGION:-eu-west-1} s3 cp $_tmpDir/tf.out s3://$TF_ARTIFACTS_S3/ma/staging/enonic/plans/${workDir}/${TRAVIS_COMMIT}.out

    rm -r $_tmpDir
}


for dir in $_scanDirs; do
    echo "---------------"
    echo "Running plan for $dir..."
    echo ""
    pushd $dir
    # Run tests
    tfPlan $dir
    popd
    echo ""
done

## Store plan to file on S3?