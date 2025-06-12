#!/bin/bash
########################################################################################################################
#                                               install_nuxeo_items.sh
########################################################################################################################
# Normal mode:
# - Update studio package (remove and install)
# - Update predefine modules on Nuxeo market place such as platform-explorer and nuxeo-api-playground
# - Update custom modules which must be available on your computer (remove and install)
#
# Hot reload mode (--reload or -r): perform a Nuxeo hot reload to update Studio configuration
########################################################################################################################
set -o errexit
set -o nounset
set -o pipefail

# ======================================================================================================================
# Declarations
# ======================================================================================================================
# shellcheck disable=SC2155
readonly SCRIPT_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC2155
readonly CONF_FILENAME="$(basename ${0%.sh}).conf"
readonly CONF_PATH="$SCRIPT_DIR/$CONF_FILENAME"

function main() {
  load_loggers_lib

  if [[ $# -ge 1 ]]; then
    case "$1" in
    --help|-h) display_help;;
    --reload|-r)
    load_nuxeo_lib
    perform_nuxeo_hot_reload;;
    *) error_and_fail "Unknown command $1" ;;
    esac
    return 0
  fi

  if [[ ! -f $CONF_PATH ]]; then
    error_and_fail "File $CONF_FILENAME is missing, please create it and configure it. $0 --help for more information"
  fi

  load_all_libs
}

# ======================================================================================================================
# Functions
# ======================================================================================================================
function display_help() {
  echo "-------------------------------------------------------------------------------------------------------------"
  echo "Normal use:
  🎯 Create $CONF_FILENAME and add the variables:
  - NUXLPER_DOCKER_IMAGE_NAME (mandatory): the Nuxeo Docker.
  Pull it with \"docker pull docker-private.packages.nuxeo.com/nuxeo/nuxeo:2025\" for instance.
  - NUXLPER_DOCKER_CONTAINER_NAME (mandatory): the name of your Nuxeo Docker container. In other terms, this is the name
  you give when you run the Nuxeo image.
  💡If you don't know Docker, see https://docs.docker.com/get-started/
  - NUXLPER_NUXEO_MODULES (optional): the custom modules you want to install with mp-install.
  syntax is \"moduleName1:path/to/module1Zip moduleName2:path/to/module2Zip ... moduleN:path/to/moduleNZip\".

  Then you are ready to launch your $0 again!"
  echo "-------------------------------------------------------------------------------------------------------------"
  echo "miscellaneous:
  🎯 --reload or -r to perform hot reload only
  🎯 --help or -h to display this help"
  echo "-------------------------------------------------------------------------------------------------------------"
}

function load_nuxeo_lib() {
  source "$SCRIPT_DIR"/nuxeo.sh
}
function load_loggers_lib() {
  source "$SCRIPT_DIR/loggers.sh"
}
function load_all_libs() {
  # 💡no need to load loggers as it already done in main.
  # shellcheck disable=SC1090
  source "${CONF_PATH}"
  load_nuxeo_lib
}
# ======================================================================================================================
main "$@"
# ================================== NOTHING BELOW PLEASE!==============================================================