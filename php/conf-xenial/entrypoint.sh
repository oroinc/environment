#!/usr/bin/env bash
[[ ! -z ${DEBUG} ]] && set -x

info () {
  [[ ! -z "${ORO_VERBOSE}" ]] && printf "\033[0;36m===> \033[0;33m%s\033[0m\n" "$1" 1>&2
}

error () {
  printf "\033[0;36m===> \033[49;31m%s\033[0m\n" "$1" 1>&2
}

export SYMFONY_ENV=${SYMFONY_ENV-prod}
echo "export SYMFONY_ENV=${SYMFONY_ENV}" | tee -a ~/.bashrc

# If xdebug enabled link a xdebug.ini
if [[ ! -z ${XDEBUG_ENABLED} ]] && [[ ${#XDEBUG_ENABLED} -gt 0 ]] && [[ ${XDEBUG_ENABLED} != "false" ]] && [[ ${XDEBUG_ENABLED} != "0" ]]; then
  ln -sf /etc/php/current/mods-available/opcache.ini /etc/php/current/fpm/conf.d/20-xdebug.ini
  ln -sf /etc/php/current/mods-available/opcache.ini /etc/php/current/cli/conf.d/20-xdebug.ini
  info "Xdebug enabled"
else
  if [[ $(find /etc/php/current/*/conf.d | grep -c "xdebug.ini") -gt 0 ]]; then
    rm /etc/php/current/{fpm,cli}/conf.d/*-xdebug.ini
  fi
  info "Xdebug disabled"
fi

# If blackfire enabled link a blackfire.ini
if [[ ! -z ${BLACKFIRE_SERVER_ID} ]] && [[ ${#BLACKFIRE_SERVER_ID} -gt 0 ]] \
&& [[ ! -z ${BLACKFIRE_SERVER_TOKEN} ]] && [[ ${#BLACKFIRE_SERVER_TOKEN} -gt 0 ]]; then
  BLACK_FIRE_CONFIG=$(envsubst < "/etc/php/current/mods-available/blackfire.ini")
  echo "$BLACK_FIRE_CONFIG" > /etc/php/current/mods-available/blackfire.ini
  ln -sf /etc/php/current/mods-available/blackfire.ini /etc/php/current/fpm/conf.d/90-blackfire.ini
  ln -sf /etc/php/current/mods-available/blackfire.ini /etc/php/current/cli/conf.d/90-blackfire.ini
  info "Blackfire enabled"
else
  rm /etc/php/current/{fpm,cli}/conf.d/*-blackfire.ini
  info "Blackfire disabled"
fi

if [[ ! -z ${OPCACHE_ENABLED} ]] && [[ ${#OPCACHE_ENABLED} -gt 0 ]] && [[ ${OPCACHE_ENABLED} != "false" ]] && [[ ${OPCACHE_ENABLED} != "0" ]]; then
  ln -sf /etc/php/current/mods-available/opcache.ini /etc/php/current/fpm/conf.d/10-opcache.ini
  ln -sf /etc/php/current/mods-available/opcache.ini /etc/php/current/cli/conf.d/10-opcache.ini
  info "OpCache enabled"
else
  if [[ $(find /etc/php/current/*/conf.d | grep -c "opcache.ini") -gt 0 ]]; then
    rm "/etc/php/current/{fpm,cli}/conf.d/*-opcache.ini"
  fi
  info "OpCache disabled"
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

if [[ "$1" = "php-fpm" ]]; then
  if [[ "${OWNER_UID}" != "0" ]]; then
    export PHP_FPM_USER=www-data
    export PHP_FPM_GROUP=www-data
  else
    export PHP_FPM_USER=root
    export PHP_FPM_GROUP=root
  fi
  
  info "Reconfigure php-fpm for ${PHP_FPM_USER}:${PHP_FPM_GROUP} (${OWNER_UID}:${OWNER_GID})"
  
  POOL_CONF="$(envsubst < /etc/php/current/fpm/pool.d/www.conf)"
  echo "${POOL_CONF}" > /etc/php/current/fpm/pool.d/www.conf
else
  if [[ "${OWNER_UID}" != "0" ]]; then
    exec gosu www-data:www-data "$@"
  fi
fi

exec "$@"
