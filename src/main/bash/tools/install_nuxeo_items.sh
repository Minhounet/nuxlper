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
readonly TOOLS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC2155
readonly LIB_DIR=$(dirname "$TOOLS_DIR")/lib
# shellcheck disable=SC2155
readonly CONF_FILENAME="$(basename "${0%.sh}").conf"
# shellcheck disable=SC2155
readonly CONF_PATH=$(dirname "$TOOLS_DIR")/$CONF_FILENAME

declare NUXLPER_NUXEO_MODULES=""
declare NUXLPER_NUXEO_MARKETPLACE_MODULES="nuxeo-web-ui nuxeo-jsf-ui platform-explorer nuxeo-api-playground"

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
  test_custom_modules_existence

  stop_nuxeo_server "$NUXLPER_DOCKER_CONTAINER_NAME"

  log_delete "Remove Studio bundle"
  remove_nuxeo_module "$NUXLPER_DOCKER_CONTAINER_NAME" "$NUXLPER_NUXEO_STUDIO_MODULE"
  ok
  remove_custom_modules

  log_clean "️Clean /tmp/nuxeo folder"
  execute_in_container "$NUXLPER_DOCKER_CONTAINER_NAME" "mkdir -p /tmp/nuxeo"
  execute_in_container "$NUXLPER_DOCKER_CONTAINER_NAME" "rm -rf /tmp/nuxeo/*"
  ok

  install_marketplace_modules
  install_studio_module
  upload_custom_modules
  install_custom_modules

  start_nuxeo_server "$NUXLPER_DOCKER_CONTAINER_NAME"
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
  - NUXLPER_NUXEO_STUDIO_MODULE (mandatory): name of your studio project
  - NUXLPER_NUXEO_MODULES (optional): the custom modules you want to install with mp-install.
  syntax is \"moduleName1:path/to/module1Zip moduleName2:path/to/module2Zip ... moduleN:path/to/moduleNZip\".

  Then you are ready to launch your $0 again!"
  echo "-------------------------------------------------------------------------------------------------------------"
  echo "miscellaneous:
  🎯 --reload or -r to perform hot reload only
  🎯 --help or -h to display this help"
  echo "-------------------------------------------------------------------------------------------------------------"
}

function test_custom_modules_existence() {
  echo "👮Test custom modules existence.."
  for entry in $NUXLPER_NUXEO_MODULES; do
      module_name="${entry%%:*}"
      module_path="${entry#*:}"
      if [[ ! -f "$module_path" ]]; then
        error "module $module_name ($module_path) does not exist"
        hint "Did you compile your modules ?"
        return 1
      fi
    done
  ok
}

function remove_custom_modules() {
  log_delete "Remove custom modules"
  for entry in $NUXLPER_NUXEO_MODULES; do
    module_name="${entry%%:*}"
    remove_nuxeo_module "$NUXLPER_DOCKER_CONTAINER_NAME" "${module_name}"
  done
  ok
}

function upload_custom_modules() {
  log_upload "Upload custom modules"
  for entry in $NUXLPER_NUXEO_MODULES; do
      module_name="${entry%%:*}"
      module_path="${entry#*:}"
      zip_name="$module_name.zip"
      copy_to_container "$NUXLPER_DOCKER_CONTAINER_NAME"  "$module_path" "/tmp/$zip_name"
      execute_in_container_as_root "$NUXLPER_DOCKER_CONTAINER_NAME"  "chown nuxeo: /tmp/$zip_name"
    done
  ok
}

function install_custom_modules() {
  log_install "Install $NUXLPER_NUXEO_MODULES from package.."
  for entry in $NUXLPER_NUXEO_MODULES; do
    module_name="${entry%%:*}"
    zip_name="$module_name.zip"
    install_nuxeo_module "$NUXLPER_DOCKER_CONTAINER_NAME" "/tmp/$zip_name"
  done
  ok
}

function install_marketplace_modules() {
  log_download "Install $NUXLPER_NUXEO_MARKETPLACE_MODULES from marketplace.."
  for entry in $NUXLPER_NUXEO_MARKETPLACE_MODULES; do
    install_nuxeo_module "$NUXLPER_DOCKER_CONTAINER_NAME" "$entry"
  done
  ok
}

function install_studio_module() {
  log_download "Install $NUXLPER_NUXEO_STUDIO_MODULE from Studio"
  install_nuxeo_module "$NUXLPER_DOCKER_CONTAINER_NAME" "$NUXLPER_NUXEO_STUDIO_MODULE"
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
  # 💡no need to load loggers as it already done in main.
  # shellcheck disable=SC1090
  source "${CONF_PATH}"
  load_nuxeo_lib
  load_docker_lib
}
# ======================================================================================================================
main "$@"
# ================================== NOTHING BELOW PLEASE!==============================================================
