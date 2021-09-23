#!/bin/bash
set -e

script_name="beaglebone-cross-compile/docker-entrypoint.sh"

# default values for options
declare -a sdk_env=()
declare -a command=()
kdir=0
sdk=''

usage() {
  cat /USAGE.txt
  exit "${1-0}" # default exit status 0
}

# Accumulate SDK-specific environment variables
sdk_export() {
  sdk_env+=("$@")
}

parse_options() {
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
    -e | --env)
      sdk_export "${2-}"
      shift
      ;;
    # separator
    --)
      shift
      break
      ;;
    # unknown
    *)
      echo "Unknown option: $1"
      usage 1
      ;;
    esac
    shift
  done

  command=("$@")

  # Check params
  if [[ -z "${sdk-}" ]]; then
    echo "Missing required parameter: sdk"
    usage 1
  fi

  # Check command
  if [[ ${#command[@]} -eq 0 ]]; then
    echo "No command provided; bailing!"
    usage 1
  fi

  return 0
}

# Process the command-line options
parse_options "$@"

# Parse the SDK option and set the SDK-specific environment variables
case "$sdk" in
  none) ;;
  gcc-arm)
    sdk_export ARCH="arm"
    sdk_export CROSS_COMPILE="${GCC_ARM_SDK}/bin/arm-none-linux-gnueabihf-"
    if [[ "$kdir" -eq 1 ]]; then
      sdk_export KDIR="/beaglebone/kernel"
    fi
    ;;
  gcc-pru)
    sdk_export CROSS_COMPILE="${GCC_PRU_SDK}/bin/pru-"
    ;;
  ti-pru)
    sdk_export PRU_CGT="${TI_PRU_SDK}"
    sdk_export PRU_SSP="${TI_PRU_SUPPORT_SDK}"
    ;;
  *)
    echo "Unknown value for 'sdk' parameter: $sdk"
    usage 1
    ;;
esac

# Print and set the SDK environment variables
if [[ "${#sdk_env[@]}" -gt 0 ]]; then
  printf "%s " "${sdk_env[@]}"
  export "${sdk_env[@]}"
fi

# Print and run the command
echo "${command[@]}"
exec "${command[@]}"
