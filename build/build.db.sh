#!/usr/bin/env bash

pushd "$(dirname "$0")" > /dev/null;DIR="$(pwd -P)";popd > /dev/null
pushd "$(dirname "$0")" > /dev/null;DIR="${DIR}/..";popd > /dev/null

MYSQL_VERSIONS="5.5 5.6 5.7 8.0";
for FILE in $(find ${DIR}/mysql/dumps -type f -name '*.gz'); do
  DUMP=$(basename ${FILE})
  TAG=$(echo ${DUMP} | rev | cut -d'/' -f1 | cut -b 14-99 | rev);
  if [[ -z "${TAG}" ]]; then
    TAG=empty
  fi
  for VERSION in ${MYSQL_VERSIONS}; do
    docker build --build-arg "DUMP=${DUMP}" -t "oroinc/mysql:${VERSION}-${TAG}" -f "${DIR}/mysql/${VERSION}/Dockerfile" "${DIR}/mysql" || {
      echo "Can't build oroinc/mysql:${VERSION}-${TAG}"
      exit 1
    }
  done
done

PGSQL_VERSIONS="9.2 9.3 9.4 9.5 9.6";
for FILE in $(find ${DIR}/pgsql/dumps -type f -name '*.gz'); do
  DUMP=$(basename ${FILE})
  TAG=$(echo ${DUMP} | rev | cut -d'/' -f1 | cut -b 14-99 | rev);
  if [[ -z "${TAG}" ]]; then
    TAG=empty
  fi
  for VERSION in ${PGSQL_VERSIONS}; do
    docker build --build-arg "DUMP=${DUMP}" -t "oroinc/pgsql:${VERSION}-${TAG}" -f "${DIR}/pgsql/${VERSION}/Dockerfile" "${DIR}/pgsql" || {
      echo "Can't build oroinc/pgsql:${VERSION}-${TAG}"
      exit 1
    }
  done
done
