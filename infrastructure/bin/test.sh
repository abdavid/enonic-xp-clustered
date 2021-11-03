#!/bin/bash
## Testing the code itself, formatting and validation (as much as possible without the need to be authenticated)
set -e

_scanDirs="$@"
_scriptDir="$(dirname $(realpath $0))"

tfTest() {
    $_scriptDir/terraform.sh fmt -check
    $_scriptDir/terraform.sh init -backend=false
    $_scriptDir/terraform.sh validate
}

for dir in $_scanDirs; do
    echo "---------------"
    echo "Testing $dir..."
    echo ""
    pushd $dir
    # Run tests
    tfTest
    popd
    echo ""
done
