#!/bin/bash
set -e

# Resolve the project directory even if the script is symlinked
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

export PROJECT_DIR=$(pwd)
export COMMAND="$@"

cd $SCRIPT_DIR
exec make run
