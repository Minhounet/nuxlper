#!/usr/bin/env bash

set -o errexit

# shellcheck disable=SC2155
readonly SCRIPT_DIR=$(dirname "$(realpath "$0")")
readonly SOURCE_FOLDER="$SCRIPT_DIR"/src/main/bash
readonly OUT_FOLDER="${SCRIPT_DIR}/build/out"
readonly DIST_FOLDER="${SCRIPT_DIR}/build/dist"
readonly TAR_FILE=nuxlper.tar
readonly VERSION_FILE=nuxlper.version

echo "⚙️Build package"
rm -rf "${SCRIPT_DIR}/build"
mkdir -p "${OUT_FOLDER}"
mkdir -p "${DIST_FOLDER}"
cp -rf "${SOURCE_FOLDER}/"* "${OUT_FOLDER}"
echo "VERSION=$(git --no-pager log | head -n1 | cut -d" " -f2)" > "${OUT_FOLDER}/${VERSION_FILE}"
cd "${OUT_FOLDER}"
tar -cf "${DIST_FOLDER}/${TAR_FILE}" ./*
echo "👍 (see ${DIST_FOLDER}/${TAR_FILE}) (version deployed: $(cat $VERSION_FILE))"
