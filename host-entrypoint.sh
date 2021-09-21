#!/bin/bash

set -e

script_name="beaglebone-cross-compile/host-entrypoint.sh"
script_dir="$(dirname "$(readlink -f "$0")")"
working_dir="$(pwd)"

cd $script_dir

if [[ "$#" -eq 0 ]]; then
  cat USAGE.txt
  exit 1
fi

case "${1-}" in
  -*)
    export BEAGLEBONE_PROJECT_DIR="$working_dir"
    export COMMAND="$@"
    exec make run
    ;;
  *)
    exec make "$@"
esac
