#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

STEP=$1;
IMAGE=oroinc/documentation:python-2.7-alpine;
FULL_BUILD=${FULL_BUILD};
BUILD_DIR=${BUILD_DIR};
APPLICATION=${APPLICATION};
PROJECT_NAME=${PROJECT_NAME:-"$(env | grep -v PATCH | grep -v CI_SKIP | grep -v SUB_NETWORK | md5sum | awk '{print $1}')"};
COMMIT_RANGE=${COMMIT_RANGE:-"origin/master...$(git rev-parse --verify HEAD)"};

case "${STEP}" in
  check)
    mkdir -p "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}" || true;
    { cd "${APPLICATION}";
      git diff --name-only --diff-filter=ACMR "${COMMIT_RANGE}" > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log";
    cd "${BUILD_DIR}"; }
    
    echo "Defining strategy for Documentation Tests...";
    if  [ -n "${FULL_BUILD}" ]; then
      echo "Full build is detected. Run all";
      return 0;
    fi
    { set +e; files=$(grep -e "^documentation" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Documentation changes were detected";
    else
      echo "Documentation build not required!";
      export CI_SKIP=1;
    fi
  ;;
  before_install)
  ;;
  install)
    docker pull "${IMAGE}";
  ;;
  before_script)
  ;;
  script)
    docker run -v "${APPLICATION}":/documentation "${IMAGE}";
  ;;
  after_script)
  ;;
esac
