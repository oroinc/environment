#!/usr/bin/env sh

[ ! -z "${DEBUG}" ] && set -x

export SYMFONY_ENV=${SYMFONY_ENV-prod}

info () {
  [ ! -z "${ORO_VERBOSE}" ] && printf "\033[0;36m===> \033[0;33m%s\033[0m\n" "$1" 1>&2
}

error () {
  printf "\033[0;36m===> \033[49;31m%s\033[0m\n" "$1" 1>&2
}

if [ "${SYMFONY_ENV}" = "dev" ]; then
  sed -i -e "s/app\.php/app_dev\.php/g" /etc/nginx/conf.d/default.conf
fi

if ping -c1 -W1 websocket >/dev/null; then
  info "Websocket host reached, proxy for websockets will be enabled"
else
  error "Websocket host is not reached, proxy for websockets will be disabled"
  rm /etc/nginx/conf.d/websocket.conf
fi

if [ "$1" = "nginx" ]; then
  OWNER_UID="$(stat -c '%u' /var/www/html/application)"
  
  info "/var/www/html/application owner is: ${OWNER_UID}"
  
  if [ "${OWNER_UID}" != "0" ] && [ "${OWNER_UID}" != "$(id -u www-data)" ]; then
    info "Changing www-data UID to ${OWNER_UID}"
    usermod -u "${OWNER_UID}" www-data
  fi
  if [ "${OWNER_UID}" != "0" ]; then
    export NGINX_USER=www-data
  else
    export NGINX_USER=root
  fi
  
  info "Reconfigure nginx for ${NGINX_USER} (${OWNER_UID})"
  
  NGINX_CONF="$(DOLLAR=$ envsubst < /etc/nginx/nginx.conf)"
  echo "${NGINX_CONF}" > /etc/nginx/nginx.conf
fi

exec "$@"
