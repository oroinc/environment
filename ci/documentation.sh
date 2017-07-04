#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

STEP=${1:-before_install};
IMAGE=oroinc/documentation:python-2.7-alpine;
ORO_APP=${ORO_APP:-};

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
  ;;
esac
