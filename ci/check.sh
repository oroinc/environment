#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

CHANGE_TARGET=${CHANGE_TARGET-master}
COMMIT_RANGE=${COMMIT_RANGE:-"origin/$CHANGE_TARGET...$(git rev-parse --verify HEAD)"};
ORO_TEST_SUITE=${1:-unit};
ORO_APP=${2:-application/platform};
pushd "$(dirname "$0")/../" >> /dev/null;BUILD_DIR="$(pwd -P)";popd >> /dev/null;

PROJECT_NAME="$(ORO=true env | grep ORO | md5sum | awk '{print $1}' | cut -b 1-7)";

# path to application
pushd "${2:-}" >> /dev/null;ORO_APP="$(pwd -P)";popd >> /dev/null;

mkdir -p "${ORO_APP}/app/logs/${PROJECT_NAME}" || true;

{ cd "${ORO_APP}";
  git diff --name-only --diff-filter=ACMR "${COMMIT_RANGE}" >> "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log";
cd "${BUILD_DIR}"; }

case "${ORO_TEST_SUITE}" in
  functional)
    echo "Defining strategy for Functional Tests...";
    { set +e; files=$(grep -e "application/" -e "package/" -e "environment/" -e "^.jenkins" -e "^Jenkinsfile" -r --exclude=\*.{feature,msi,ods,psd,bat,gif,gitignore,gitkeep,html,jpg,jpeg,md,mp4,png,py,rst,txt,gliffy,css,js,less,scss,cur,eot,ico,svg,ttf,woff,woff2,xlsx} "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Changes were detected";
    else
      echo "Build not required!";
    fi
  ;;
  unit)
    echo "Defining strategy for Unit Tests...";
    { set +e; files=$(grep -e "application/" -e "package/" -e "environment/" -e "^Jenkinsfile" -e "^.jenkins" -r --exclude=\*.{feature,msi,ods,psd,bat,gif,gitignore,gitkeep,html,jpg,jpeg,md,mp4,png,py,rst,txt,gliffy,css,js,less,scss,cur,eot,ico,svg,ttf,woff,woff2,xlsx} "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Changes were detected";
    else
      echo "Build not required!";
    fi
  ;;
  documentation)
    echo "Defining strategy for Documentation Tests...";
    { set +e; files=$(grep -e "^Jenkinsfile" -e "^.jenkins" -e "^documentation" "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Changes were detected";
    else
      echo "Build not required!";
    fi
  ;;
  javascript)
    echo "Defining strategy for JS Tests...";
    { set +e; files=$(grep -e "^Jenkinsfile" -e "^.jenkins" -e "^.*\.js$" -e "^.*\.php$" "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Changes were detected";
    else
      echo "Build not required!";
    fi
  ;;
  behat)
    echo "Defining strategy for Behat Tests...";
    { set +e; files=$(grep -e "application/" -e "package/" -e "environment/" -e "^Jenkinsfile" -e "^.jenkins" -r --exclude=\*.{msi,ods,psd,bat,gif,gitignore,gitkeep,html,jpg,jpeg,md,mp4,png,py,rst,txt,gliffy} "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Changes were detected";
    else
      echo "Build not required!";
    fi
  ;;
  behat_wiring)
    echo "Defining strategy for behat_wiring Tests...";
    { set +e; files=$(grep -e "application/" -e "package/" -e "environment/" -e "^Jenkinsfile" -e "^.jenkins" -r --exclude=\*.{msi,ods,psd,bat,gif,gitignore,gitkeep,html,jpg,jpeg,md,mp4,png,py,rst,txt,gliffy} "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Changes were detected";
    else
      echo "Build not required!";
    fi
  ;;
  duplicate-queries)
    echo "Defining strategy for duplicate-queries Tests...";
    { set +e; files=$(grep -e "^Jenkinsfile" -e "^.jenkins" -e "^application/" -e "^package/" -r --exclude=\*.{feature,msi,ods,psd,bat,gif,gitignore,gitkeep,html,jpg,jpeg,md,mp4,png,py,rst,txt,gliffy,css,js,less,scss,cur,eot,ico,svg,ttf,woff,woff2,xlsx} "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Changes were detected";
    else
      echo "Build not required!";
    fi
  ;;
  patch_update)
    echo "Defining strategy for patch_update Tests...";
    { set +e; files=$(grep -e "^Jenkinsfile" -e "^.jenkins" "${ORO_APP}/app/logs/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Changes were detected";
    else
      echo "Build not required!";
    fi
  ;;
esac
