#!/bin/bash
set -e
## commons
. $(dirname $0)/.common.sh
## Set of common/helper functions

# Method tries to find the closest binary that could be run for given context
# Args: <command> <path> [...opts]
# - Use <command> from <path>/bin dir if exists
# - Use <command> from bin dir if exists
# - Display "Command not found" error

_scriptDir=$(dirname $0)
_command=$1
_path=$2

if [ -x "$_path/bin/$_command.sh" ]; then
    _runCmd="$_path/bin/$_command.sh"
elif [ -x "${_scriptDir}/$_command.sh" ]; then
    _runCmd="${_scriptDir}/$_command.sh"
else
    echoError 1 "Command <$_command> not found"
fi

$_runCmd ${@:3}
