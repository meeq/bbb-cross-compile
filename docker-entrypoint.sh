#!/bin/bash
set -e

if [[ $# -eq 0 ]]; then
    exec echo 'No command specified; bailing!'
fi

exec "$@"
