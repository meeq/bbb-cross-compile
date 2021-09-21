#!/bin/bash
set -e

# Resolve the project directory even if the script is symlinked
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

WORKING_DIR="$(pwd)"
export BEAGLEBONE_PROJECT_DIR="$WORKING_DIR"

cd $SCRIPT_DIR

if [[ "$#" -eq 0 ]]; then
  exec make help
fi

case "${1-}" in
  -*) 
    export COMMAND="$@"
    exec make run
    ;;
  *)
    exec make "$1"
esac
