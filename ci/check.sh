#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o errtrace
set -o nounset

DEBUG=${DEBUG-}
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

CHANGE_TARGET=${CHANGE_TARGET-master}
COMMIT_RANGE=${COMMIT_RANGE:-"origin/$CHANGE_TARGET...$(git rev-parse --verify HEAD)"}
ORO_TEST_SUITE=${1:-unit}
ORO_APP=${2:-application/platform}
PROJECT_NAME="${PROJECT_NAME-$(ORO=true env | grep ORO | md5sum | awk '{print $1}' | cut -b 1-7)}"
DIR_DIFF="${DIR_DIFF-${ORO_APP}/app/logs/${PROJECT_NAME}}"
FILE_DIFF="${FILE_DIFF-diff.log}"

# path to application
pushd "${2:-}" >>/dev/null
ORO_APP="$(pwd -P)"
popd >>/dev/null

mkdir -p "$DIR_DIFF" || :

pushd "${ORO_APP}"
git diff --name-only --diff-filter=ACMR "${COMMIT_RANGE}" >>"$DIR_DIFF/$FILE_DIFF"
popd

case "${ORO_TEST_SUITE}" in
functional)
  echo "Defining strategy for Functional Tests..."
  set +e
  files=$(grep -e "^application/" -e "^package/" -e "^environment/" -e "^Jenkinsfile" -e "^.jenkins" "$DIR_DIFF/$FILE_DIFF" | grep -v -E "\.(feature|msi|ods|psd|bat|gif|gitignore|gitkeep|html|jpg|jpeg|md|mp4|png|py|rst|txt|gliffy|css|js|less|scss|cur|eot|ico|svg|ttf|woff|woff2|xlsx)$")
  set -e
  if [[ "${files}" ]]; then
    echo "Changes were detected"
  else
    echo "Changes weren't detected. Build is not required"
  fi
  ;;
unit)
  echo "Defining strategy for Unit Tests..."
  set +e
  files=$(grep -e "^application/" -e "^package/" -e "^environment/" -e "^Jenkinsfile" -e "^.jenkins" "$DIR_DIFF/$FILE_DIFF" | grep -v -E "\.(feature|msi|ods|psd|batods|psd|bat|gif|gitignore|gitkeep|html|jpg|jpeg|md|mp4|png|py|rst|txt|gliffy|css|js|less|scss|cur|eot|ico|svg|ttf|woff|woff2|xlsxgif|gitignore|gitkeep|html|jpg|jpeg|md|mp4|png|py|rst|txt|gliffy|css|js|less|scss|cur|eot|ico|svg|ttf|woff|woff2|xlsx)$")
  set -e
  if [[ "${files}" ]]; then
    echo "Changes were detected"
  else
    echo "Changes weren't detected. Build is not required"
  fi
  ;;
documentation)
  echo "Defining strategy for Documentation Tests..."
  set +e
  files=$(grep -e "^documentation" -e "^environment/" -e "^Jenkinsfile" -e "^.jenkins" "$DIR_DIFF/$FILE_DIFF")
  set -e
  if [[ "${files}" ]]; then
    echo "Changes were detected"
  else
    echo "Changes weren't detected. Build is not required"
  fi
  ;;
javascript)
  echo "Defining strategy for JS Tests..."
  set +e
  files=$(grep -e "\.js$" -e "^environment/" -e "^Jenkinsfile" -e "^.jenkins" "$DIR_DIFF/$FILE_DIFF")
  set -e
  if [[ "${files}" ]]; then
    echo "Changes were detected"
  else
    echo "Changes weren't detected. Build is not required"
  fi
  ;;
php_code_style)
  echo "Defining strategy for CS Tests..."
  set +e
  files=$(grep -e "\.php$" -e "^environment/" -e "^Jenkinsfile" -e "^.jenkins" "$DIR_DIFF/$FILE_DIFF")
  set -e
  if [[ "${files}" ]]; then
    echo "Changes were detected"
  else
    echo "Changes weren't detected. Build is not required"
  fi
  ;;
behat)
  echo "Defining strategy for Behat Tests..."
  set +e
  files=$(grep -e "^application/" -e "^package/" -e "^environment/" -e "^environment/" -e "^Jenkinsfile" -e "^.jenkins" "$DIR_DIFF/$FILE_DIFF" | grep -v -E "\.(msi|ods|psd|bat|gif|gitignore|gitkeep|html|jpg|jpeg|md|mp4|png|py|rst|txt|gliffy)$")
  set -e
  if [[ "${files}" ]]; then
    echo "Changes were detected"
  else
    echo "Changes weren't detected. Build is not required"
  fi
  ;;
behat_wiring)
  echo "Defining strategy for behat_wiring Tests..."
  set +e
  files=$(grep -e "^application/" -e "^package/" -e "^environment/" -e "^Jenkinsfile" -e "^.jenkins" "$DIR_DIFF/$FILE_DIFF" | grep -v -E "\.(msi|ods|psd|bat|gif|gitignore|gitkeep|html|jpg|jpeg|md|mp4|png|py|rst|txt|gliffy)$")
  set -e
  if [[ "${files}" ]]; then
    echo "Changes were detected"
  else
    echo "Changes weren't detected. Build is not required"
  fi
  ;;
duplicate-queries | patch_update)
  echo "Defining strategy for duplicate-queries Tests..."
  set +e
  files=$(grep -e "^application/" -e "^package/" -e "^environment/" -e "^Jenkinsfile" -e "^.jenkins" "$DIR_DIFF/$FILE_DIFF" | grep -v -E "\.(feature|msi|ods|psd|bat|gif|gitignore|gitkeep|html|jpg|jpeg|md|mp4|png|py|rst|txt|gliffy|css|js|less|scss|cur|eot|ico|svg|ttf|woff|woff2|xlsx)$")
  set -e
  if [[ "${files}" ]]; then
    echo "Changes were detected"
  else
    echo "Changes weren't detected. Build is not required"
  fi
  ;;
esac
