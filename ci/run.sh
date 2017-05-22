#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

trap clean_up ERR EXIT INT TERM;

bash --version | grep 'version 4' > /dev/null;
docker --version > /dev/null;
docker-compose --version > /dev/null;
parallel --version | grep '2017' > /dev/null;

parallel --record-env;
mv ~/.parallel/ignored_vars ~/.parallel/ignored_vars.backup
grep -v DOCKER ~/.parallel/ignored_vars.backup > ~/.parallel/ignored_vars

# environment folder
pushd "$(dirname "$0")/../" > /dev/null;BUILD_DIR="$(pwd -P)";popd > /dev/null;
export BUILD_DIR;

SYMFONY_DEBUG=0;
export SYMFONY_DEBUG;

# unit, functional, behat
TEST_SUITE=$1;
export TEST_SUITE;

if [[ ${TEST_SUITE} == "functional" ]]; then
  export SYMFONY_ENV=test;
fi

# path to application
pushd "$2" > /dev/null;APPLICATION="$(pwd -P)";popd > /dev/null;
export APPLICATION;

CI_SKIP=0;

TEST_RUNNER_OPTIONS=${3:-};
export TEST_RUNNER_OPTIONS;

NETWORK=$(( ( RANDOM % 255 )  + 1 ));
export NETWORK;
SUB_NETWORK=$(( ( RANDOM % 255 )  + 1 ));
export SUB_NETWORK;

function check_codes {
  if [ ${CI_SKIP} -ne 0 ]; then exit 0; fi;
}

function clean_up {
  rm -rf mv ~/.parallel/ignored_vars* || true;
  "${BUILD_DIR}/ci/${TEST_SUITE}.sh" after_script;
}

PROJECT_NAME="$(env | grep -v PATCH | grep -v CI_SKIP | grep -v SUB_NETWORK | md5sum | awk '{print $1}')";
export PROJECT_NAME;

rm -f "{BUILD_DIR}/ci/artifacts/${PROJECT_NAME}" || true;
mkdir -p "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}" || true;

time "${BUILD_DIR}/ci/${TEST_SUITE}.sh" after_script   ; check_codes;
time "${BUILD_DIR}/ci/${TEST_SUITE}.sh" before_install | tee -a "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/${TEST_SUITE}.1.before_install.log" || true; check_codes;
time "${BUILD_DIR}/ci/${TEST_SUITE}.sh" install        | tee -a "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/${TEST_SUITE}.2.install.log"        || true; check_codes;
time "${BUILD_DIR}/ci/${TEST_SUITE}.sh" before_script  | tee -a "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/${TEST_SUITE}.3.before_script.log"  || true; check_codes;
time "${BUILD_DIR}/ci/${TEST_SUITE}.sh" script         | tee -a "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/${TEST_SUITE}.4.script.log"         || true; check_codes;
time "${BUILD_DIR}/ci/${TEST_SUITE}.sh" after_script   ; check_codes;

trap - ERR EXIT INT TERM;
