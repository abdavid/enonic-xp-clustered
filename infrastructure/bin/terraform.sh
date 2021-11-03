#!/bin/bash
set -e

source $(dirname $0)/.common.sh
_tfVersion=${TF_VERSION:?No terraform version defined. Please set TF_VERSION}
_tf_bin=$(ensureTerraform $_tfVersion)

${_tf_bin} $@