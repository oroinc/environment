#!/usr/bin/env bash

info () {
  [[ ! -z "${ORO_VERBOSE}" ]] && printf "\033[0;36m===> \033[0;33m%s\033[0m\n" "$1"
}

error () {
  printf "\033[0;36m===> \033[49;31m%s\033[0m\n" "$1"
}

[[ ! -z ${DEBUG} ]] && set -x

export SYMFONY_ENV=${SYMFONY_ENV-prod}

[[ ! -z ${GITHUB_OAUTH} ]] && composer config -g github-oauth.github.com "${GITHUB_OAUTH}"

[[ -d "${COMPOSER_HOME}/auth" ]] && [[ ! -f "${COMPOSER_HOME}/auth/auth.json" ]] && echo '{}' > "${COMPOSER_HOME}/auth/auth.json"

ln -sf "${COMPOSER_HOME}/auth/auth.json" "${COMPOSER_HOME}/auth.json"

if [[ -d /var/www/package ]] && [[ "$(ls -A /var/www/package)" ]]; then
  export COMPOSER=dev.json
fi

OWNER_UID="$(stat -c '%u' /var/www/html/application)"
OWNER_GID="$(stat -c '%g' /var/www/html/application)"

info "/var/www/html/application owner is: ${OWNER_UID}:${OWNER_GID}"

if [[ "${OWNER_UID}" != "0" ]] && [[ "${OWNER_UID}" != "$(id -u www-data)" ]]; then
  info "Changing www-data UID to ${OWNER_UID}"
  usermod -u "${OWNER_UID}" www-data
fi

if [[ "${OWNER_GID}" != "0" ]] && [[ "${OWNER_GID}" != "$(id -g www-data)" ]]; then
  info "Changing www-data GID to ${OWNER_GID}"
  groupmod -g "${OWNER_GID}" www-data > /dev/null 2>&1
fi

[[ $(stat -c '%u' "${COMPOSER_HOME}") != "${OWNER_UID}" ]] && chown -R "${OWNER_UID}:${OWNER_GID}" "${COMPOSER_HOME}"

[[ ! -f /var/www/html/application/app/config/parameters.yml ]] \
&& [[ -d /var/www/html/application/app/cache ]] \
&& find /var/www/html/application/app/cache/* -maxdepth 1 -type d | awk  -F'/' '{print $NF}' | grep 'dev\|prod\|test' > /dev/null 2>&1 && {
  info "Possible the application cache is outdated, deleting..."
  (rm -rf /var/www/html/application/app/cache/* && {
      info "Application cache for all environments deleted successfully"
    }) || {
    error "Can't delete application cache"
  }
}

if [[ "$(id -u)" = "0" ]] && [[ "${OWNER_UID}" != "0" ]]; then
  exec gosu www-data:www-data /docker-entrypoint.sh "$@"
fi

exec /docker-entrypoint.sh "$@"
