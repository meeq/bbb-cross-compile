#!/bin/bash
set -e

script_name="bb-cross-compile/docker-entrypoint.sh"

usage() {
  local code=${1-0} # default exit status 0
  cat <<EOF
Usage: ${script_name} [-h] [-v] [-k] --sdk SDK -- COMMAND

Run commands using various cross-compilers for BeagleBone Black.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print debug info
-c, --sdk       Select a cross-compiler: gcc-arm gcc-pru ti-pru
-k, --kdir      (gcc-arm only) set the KDIR environment variable
                (You only need this when compiling kernel modules)
EOF
  exit "$code"
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_options() {
  # default values of variables set from options
  kdir=0
  sdk=''

  while :; do
    case "${1-}" in
    # meta
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    # flags
    -k | --kdir) kdir=1 ;;
    # params
    -c | --sdk)
      sdk="${2-}"
      shift
      ;;
    # separator
    --)
      shift
      break
      ;;
    # unknown
    *) die "Unknown option: $1" ;;
    esac
    shift
  done

  command=("$@")

  # Check params
  if [[ -z "${sdk-}" ]]; then
    msg "Missing required parameter: sdk"
    usage 1
  fi

  # Check command
  if [[ ${#command[@]} -eq 0 ]]; then
    msg "No command provided; bailing!"
    usage 1
  fi

  return 0
}

# Capture SDK-specific environment variables so they can be printed
declare -a sdk_env=()
sdk_export() {
  local keyval=$1
  sdk_env+=("$keyval")
}

# Process the command-line options
parse_options "$@"

# Parse the SDK option and set the SDK-specific environment variables
case "$sdk" in
  gcc-arm)
    sdk_export ARCH="arm"
    sdk_export CROSS_COMPILE="${GCC_ARM_SDK}/bin/arm-none-linux-gnueabihf-"
    if [[ "$kdir" -eq 1 ]]; then
      sdk_export KDIR="/bb-kernel"
    fi
    ;;
  gcc-pru) sdk_export CROSS_COMPILE="${GCC_PRU_SDK}/bin/pru-" ;;
  ti-pru) sdk_export PRU_CGT="${TI_PRU_SDK}" ;;
  *) die "Unknown sdk: $sdk" ;;
esac

# Run the command with the SDK environment variables
echo "${sdk_env[@]} ${command[@]}"
export "${sdk_env[@]}"
exec "${command[@]}"
