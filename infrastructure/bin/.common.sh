#!/bin/bash
set -e

TF_DEFAULT_VERSION=0.14.6

echoError() {
    echo ${@:2} >&2
    exit $1
}

getCurrentOS() {
    _os=$(uname -s)

    case $_os in
    "Darwin")
        _returnOs="darwin"
        ;;
    "Linux")
        _returnOs="linux"
        ;;
    *)
        echoError 1 "Unsupported OS $_os"
        ;;
    esac

    echo $_returnOs
}

getCurrentArch() {
    _arch=$(uname -m)

    case $_arch in
    "x86_64")
        _returnArch="amd64"
        ;;
    *)
        echoError 2 "Unsupported Arch $_arch"
        ;;
    esac

    echo $_returnArch
}

ensureTerraform() {
    set -e
    # Define version
    _version=${1:-$TF_DEFAULT_VERSION}
    _os=$(getCurrentOS)
    _arch=$(getCurrentArch)

    _binaryPath=$HOME/bin/terraform-${_version}

    # Return the binary path
    echo $_binaryPath
    # Check if exists; continue if not
    [ -x "${_binaryPath}" ] && return


    # Download
    _tempDir=$(mktemp -d)
    echo curl -s -o ${_tempDir}/terraform.zip https://releases.hashicorp.com/terraform/${_version}/terraform_${_version}_${_os}_${_arch}.zip >&2
    curl -s -o ${_tempDir}/terraform.zip https://releases.hashicorp.com/terraform/${_version}/terraform_${_version}_${_os}_${_arch}.zip >&2

    # Unpack
    cd $_tempDir >&2
    unzip ${_tempDir}/terraform.zip >&2
    chmod +x ${_tempDir}/terraform >&2

    # Move to destination
    mkdir -p $HOME/bin >&2
    mv terraform ${_binaryPath} >&2
}
