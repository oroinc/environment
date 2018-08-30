#!/usr/bin/env bash

BIN_CONSOLE="app/console"
CONFIG_DIR="app/config"
if [[ ! -f ${BIN_CONSOLE} ]]
then
  BIN_CONSOLE="bin/console"
  CONFIG_DIR="config"
fi

[[ ! -z ${DEBUG} ]] && set -x

info () {
  [[ ! -z "${ORO_VERBOSE}" ]] && printf "\033[0;36m===> \033[0;33m%s\033[0m\n" "$1"
}

error () {
  printf "\033[0;36m===> \033[49;31m%s\033[0m\n" "$1"
}

is_installed () {
  if [[ -f ${CONFIG_DIR}/parameters.yml ]] && [[ $(grep ".*installed:\s*[\']\{0,1\}[a-zA-Z0-9\:\+\-]\{1,\}[\']\{0,1\}" ${CONFIG_DIR}/parameters.yml | grep -c "null\|false") -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

if ! is_installed; then
  # Wait until application will be installed
  until is_installed; do
    sleep 2;
  done
  info "Application installed, waiting for 300 seconds before starting..."
  sleep 300 # Waiting for cache warm up at first run
else
  info "Starting in 60 seconds..."
  sleep 60
fi

if [[ ! -z ${DEBUG} ]]; then
  CMD='oro:message-queue:consume -vvv'
else
  CMD='oro:message-queue:consume'
fi

while :
do
  info "Running '$CMD' command"
  (php ${BIN_CONSOLE} ${CMD} && {
      info "Consumer finished with exit code: $?"
    }) || {
    error "Consumer failed with exit code: $?"
  }
  info "Restarting in 15 seconds..."
  sleep 15
done
