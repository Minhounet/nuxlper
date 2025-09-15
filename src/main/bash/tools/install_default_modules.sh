#!/bin/bash
########################################################################################################################
#                                               install_default_modules.sh
########################################################################################################################
# Install web-ui and some friends
########################################################################################################################
set -o errexit
set -o nounset
set -o pipefail

# ======================================================================================================================
# Declarations
# ======================================================================================================================
# shellcheck disable=SC2155
readonly TOOLS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC2155
readonly LIB_DIR=$(dirname "$TOOLS_DIR")/lib
# shellcheck disable=SC2155
readonly CONF_FILENAME="nuxlper.conf"
# shellcheck disable=SC2155
readonly TEMPLATES_DIR=$(dirname "$TOOLS_DIR")/templates
# shellcheck disable=SC2155
readonly CONF_PATH=$(dirname "$TOOLS_DIR")/$CONF_FILENAME

declare NUXLPER_NUXEO_MARKETPLACE_MODULES="nuxeo-web-ui nuxeo-jsf-ui platform-explorer nuxeo-api-playground"
declare NUXLPER_NUXEO_SERVER_LOG="/var/log/nuxeo/server.log"

function main() {
  load_loggers_lib

  if [[ ! -f $CONF_PATH ]]; then
    error_and_fail "File $CONF_FILENAME is missing, please create it and configure it. $0 --help for more information"
  fi

  load_all_libs

  stop_nuxeo_server "$NUXLPER_NUXEO_CONTAINER_NAME"
  install_marketplace_modules
  start_nuxeo_server "$NUXLPER_NUXEO_CONTAINER_NAME"
  
}

# ======================================================================================================================
# Functions
# ======================================================================================================================
function install_marketplace_modules() {
  log_download "Install $NUXLPER_NUXEO_MARKETPLACE_MODULES from marketplace.."
  for entry in $NUXLPER_NUXEO_MARKETPLACE_MODULES; do
    install_nuxeo_module "$NUXLPER_NUXEO_CONTAINER_NAME" "$entry"
  done
  ok
}

function load_nuxeo_lib() {
  source "$LIB_DIR"/nuxeo.sh
}
function load_loggers_lib() {
  source "$LIB_DIR/loggers.sh"
}
function load_docker_lib() {
  source "$LIB_DIR/docker.sh"
}
function load_all_libs() {
  load_conf
  load_nuxeo_lib
  load_docker_lib
}

function load_conf() {
  # 💡no need to load loggers as it already done in main.
  # shellcheck disable=SC1090
  source "${CONF_PATH}"
}

# ======================================================================================================================
main "$@"
# ================================== NOTHING BELOW PLEASE!==============================================================
