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
  fi
  return 1
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

while :
do
  START_TIME=$(date +%s)
  info "Running 'php $BIN_CONSOLE oro:cron' command"
  (php ${BIN_CONSOLE} oro:cron && {
      info "The oro:cron command finished with exit code: $?"
    }) || {
    error "The oro:cron command failed with exit code: $?"
  }
  
  LEFT_TIME=$((60-$(($(date +%s)-START_TIME))))
  [[ ${LEFT_TIME} -gt 0 ]] && (info "Sleeping for ${LEFT_TIME} seconds" && sleep ${LEFT_TIME})
done
