#!/usr/bin/env bash
[[ ! -z ${DEBUG} ]] && set -x

if [ "$1" = "elasticsearch" ]
then
  EXTRA_ARGS="-Des.node.name=$(hostname) -Des.cluster.name=$(hostname)"
else
  EXTRA_ARGS=""
fi

exec /bin/bash -c "/docker-entrypoint.sh $* ${EXTRA_ARGS}"
