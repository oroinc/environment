#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

STEP=${1:-before_install};
IMAGE=oroinc/documentation:sphinx-warning-file;
ORO_APP=${ORO_APP:-};
SPHINX_ERROR_FILENAME=${ORO_APP}/sphinx-build-errors.log;

case "${STEP}" in
  before_install)
  ;;
  install)
    docker pull "${IMAGE}";
  ;;
  before_script)
  ;;
  script)
    docker run --env DOCUMENTATION_BUILDDIR=${DOCUMENTATION_BUILDDIR:-_build} -v "${ORO_APP}":/documentation "${IMAGE}";
  ;;
  after_script)
    # If file with errors has content then show it and exit with errorcode
    if [[ -s ${SPHINX_ERROR_FILENAME} ]]; then
        cat ${SPHINX_ERROR_FILENAME};
        rm -f ${SPHINX_ERROR_FILENAME};
        exit 1;
    fi
    rm -f ${SPHINX_ERROR_FILENAME} || true;
  ;;
esac
