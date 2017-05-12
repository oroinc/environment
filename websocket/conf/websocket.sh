#!/usr/bin/env bash

[[ ! -z ${DEBUG} ]] && set -x

info () {
  [[ ! -z "${ORO_VERBOSE}" ]] && printf "\033[0;36m===> \033[0;33m%s\033[0m\n" "$1"
}

error () {
  printf "\033[0;36m===> \033[49;31m%s\033[0m\n" "$1"
}

is_installed () {
  if [[ -f app/config/parameters.yml ]] && [[ $(grep ".*installed:\s*[\']\{0,1\}[a-zA-Z0-9\:\+\-]\{1,\}[\']\{0,1\}" app/config/parameters.yml | grep -c "null\|false") -eq 0 ]]; then
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
  info "Application installed, starting in 300 seconds..."
  sleep 300
else
  info "Starting in 60 seconds..."
  sleep 60
fi

while :
do
  info "Running 'php app/console clank:server' command"
  (php app/console clank:server && {
      info "Clank server finished with exit code: $?"
    }) || {
    error "Clank server failed with exit code: $?"
  }
  info "Restarting in 15 seconds..."
  sleep 15
done
