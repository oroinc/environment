#!/usr/bin/env bash

pushd "$(dirname "$0")" > /dev/null;DIR="$(pwd -P)";popd > /dev/null

CHECK=${1:-"$DIR"/..}

# https://github.com/koalaman/shellcheck
find "$CHECK" -type f -iname '*.sh' -print -exec shellcheck \
-e SC2086 -e SC1004 -e SC2181 -e SC2094 -e SC2128 -e SC2178 \
-e SC2016 -e SC2098 -e SC2096 -e SC2097 -e SC2044 -e SC2046 \
-e SC2126 -e SC2172 \
{} \;

# https://github.com/bemeurer/beautysh
find "$CHECK" -type f -iname '*.sh' -print -exec beautysh -i 2 --files {} \;

find "$CHECK" -type f -iname '*.sh' -print -exec bash -n {} \;
