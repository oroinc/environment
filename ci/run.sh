#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

function requirement {
  test 0 -lt $($1 | grep -ie $2 | wc -l) || (echo "$1 $2 required" && exit 1);
}

requirement 'docker --version' '17\.[0-9][0-9]';
requirement 'docker-compose --version' '1\.1[0-9]';
requirement 'parallel --version' '2017';

if [[ ! -f ~/.parallel/ignored_vars ]]; then
  mkdir ~/.parallel/ || true
  parallel --record-env;
  cp ~/.parallel/ignored_vars ~/.parallel/ignored_vars.bkp;
  grep -vi docker ~/.parallel/ignored_vars.bkp | grep -vi oro > ~/.parallel/ignored_vars;
fi

# environment folder
pushd "$(dirname "$0")/../" >> /dev/null;BUILD_DIR="$(pwd -P)";popd >> /dev/null;

# unit, functional, behat
ORO_TEST_SUITE=${1:-unit};

PROJECT_NAME="$(ORO=true env | grep ORO | md5sum | awk '{print $1}' | cut -b 1-7)";

TEST_RUNNER_OPTIONS=${3:-};

# path to application
pushd "${2:-}" >> /dev/null;ORO_APP="$(pwd -P)";popd >> /dev/null;

mkdir -p "${ORO_APP}/app/logs/${PROJECT_NAME}" || true;

NETWORK=${NETWORK:-$(( ( RANDOM % 200 )  + 55 ))};
SUB_NETWORK=${SUB_NETWORK:-$(( ( RANDOM % 200 )  + 55 ))};

function run_script {
  time \
  BUILD_DIR=${BUILD_DIR} \
  ORO_TEST_SUITE=${ORO_TEST_SUITE} \
  ORO_APP=${ORO_APP} \
  PROJECT_NAME=${PROJECT_NAME} \
  TEST_RUNNER_OPTIONS=${TEST_RUNNER_OPTIONS} \
  NETWORK=${NETWORK} \
  SUB_NETWORK=${SUB_NETWORK} \
  "${BUILD_DIR}/ci/${ORO_TEST_SUITE}.sh" "$1" | tee -a "${ORO_APP}/app/logs/${PROJECT_NAME}/${ORO_TEST_SUITE}.$2.log";
}

function clean_up {
  run_script 'after_script' '6.cleanup';
  if [[ -n "${1:-}" ]]; then
    exit 1;
  fi
}

trap 'clean_up 1' 1 2 3 8 14 15;

clean_up;
run_script 'before_install' '1.before_install' || clean_up 1;
run_script 'install' '2.install'               || clean_up 1;
run_script 'before_script' '3.before_script'   || clean_up 1;
run_script 'script' '4.script'                 || clean_up 1;
clean_up;
