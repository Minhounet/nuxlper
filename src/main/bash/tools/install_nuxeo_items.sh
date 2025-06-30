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
readonly CONF_FILENAME="nuxlper.conf"
# shellcheck disable=SC2155
readonly TEMPLATES_DIR=$(dirname "$TOOLS_DIR")/templates
# shellcheck disable=SC2155
readonly CONF_PATH=$(dirname "$TOOLS_DIR")/$CONF_FILENAME

declare NUXLPER_NUXEO_MODULES=""
declare NUXLPER_NUXEO_MARKETPLACE_MODULES="nuxeo-web-ui nuxeo-jsf-ui platform-explorer nuxeo-api-playground"
declare NUXLPER_NUXEO_SERVER_LOG="/var/log/nuxeo/server.log"

function main() {
  local install_studio_only="n"
  local restart_nuxeo_only="n"
  load_loggers_lib
  if [[ $# -ge 1 ]]; then
    case "$1" in
    --help|-h) display_help;;
    --restart|-ro) restart_nuxeo_only="y";;
    --reload|-r)
      load_nuxeo_lib
      perform_nuxeo_hot_reload
      return 0;;
    --studio-only|-so) install_studio_only="y";;
    *) error_and_fail "Unknown command $1" ;;
    esac

  fi

  if [[ ! -f $CONF_PATH ]]; then
    error_and_fail "File $CONF_FILENAME is missing, please create it and configure it. $0 --help for more information"
  fi

  load_all_libs

  if [[ "$restart_nuxeo_only" == "y" ]]; then
    restart_nuxeo_server "$NUXLPER_NUXEO_CONTAINER_NAME"
    wait_for_user_input_after_server_start
    return 0
  fi

  test_custom_modules_existence

  stop_nuxeo_server "$NUXLPER_NUXEO_CONTAINER_NAME"

  log_delete "Remove Studio bundle"
  remove_nuxeo_module "$NUXLPER_NUXEO_CONTAINER_NAME" "$NUXLPER_NUXEO_STUDIO_MODULE"
  ok
  remove_custom_modules

  log_clean "️Clean /tmp/nuxeo folder"
  execute_in_container "$NUXLPER_NUXEO_CONTAINER_NAME" "mkdir -p /tmp/nuxeo"
  execute_in_container "$NUXLPER_NUXEO_CONTAINER_NAME" "rm -rf /tmp/nuxeo/*"
  ok

  install_marketplace_modules
  install_studio_module
  upload_custom_modules
  install_custom_modules

  start_nuxeo_server "$NUXLPER_NUXEO_CONTAINER_NAME"
  wait_for_user_input_after_server_start
}

# ======================================================================================================================
# Functions
# ======================================================================================================================
function display_help() {
  echo "-------------------------------------------------------------------------------------------------------------"
  echo "Normal use:
  🎯 Create $CONF_FILENAME and add contents from $TEMPLATES_DIR/nuxlper.conf.install_nuxeo_items"
  cat "$TEMPLATES_DIR"/nuxlper.conf.install_nuxeo_items
  echo "Then you are ready to launch your $0 again!"
  echo "-------------------------------------------------------------------------------------------------------------"
  echo "miscellaneous:
  🎯 --reload or -r to perform hot reload only
  🎯 --help or -h to display this help"
  echo "-------------------------------------------------------------------------------------------------------------"
}

function test_custom_modules_existence() {
  if is_only_studio_install "ignore modules existence"; then
    return 0
  fi

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
  if is_only_studio_install "ignore modules removal"; then
    return 0
  fi

  log_delete "Remove custom modules"
  for entry in $NUXLPER_NUXEO_MODULES; do
    module_name="${entry%%:*}"
    remove_nuxeo_module "$NUXLPER_NUXEO_CONTAINER_NAME" "${module_name}"
  done
  ok
}

function upload_custom_modules() {
  if is_only_studio_install "dont upload custom modules"; then
    return 0
  fi
  log_upload "Upload custom modules"
  for entry in $NUXLPER_NUXEO_MODULES; do
      module_name="${entry%%:*}"
      module_path="${entry#*:}"
      zip_name="$module_name.zip"
      copy_to_container "$NUXLPER_NUXEO_CONTAINER_NAME"  "$module_path" "/tmp/$zip_name"
      execute_in_container_as_root "$NUXLPER_NUXEO_CONTAINER_NAME"  "chown nuxeo: /tmp/$zip_name"
    done
  ok
}

function install_custom_modules() {
  if is_only_studio_install "dont install custom modules"; then
      return 0
  fi
  log_install "Install $NUXLPER_NUXEO_MODULES from package.."
  for entry in $NUXLPER_NUXEO_MODULES; do
    module_name="${entry%%:*}"
    zip_name="$module_name.zip"
    install_nuxeo_module "$NUXLPER_NUXEO_CONTAINER_NAME" "/tmp/$zip_name"
  done
  ok
}

function install_marketplace_modules() {
  if is_only_studio_install "dont install marketplace modules"; then
      return 0
  fi
  log_download "Install $NUXLPER_NUXEO_MARKETPLACE_MODULES from marketplace.."
  for entry in $NUXLPER_NUXEO_MARKETPLACE_MODULES; do
    install_nuxeo_module "$NUXLPER_NUXEO_CONTAINER_NAME" "$entry"
  done
  ok
}

function install_studio_module() {
  log_download "Install $NUXLPER_NUXEO_STUDIO_MODULE from Studio"
  install_nuxeo_module "$NUXLPER_NUXEO_CONTAINER_NAME" "$NUXLPER_NUXEO_STUDIO_MODULE"
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

function is_only_studio_install() {
  if [[ ! -v install_studio_only ]]; then
    return 1
  fi
  if [[ "$install_studio_only" == "y" ]]; then
    info "Skip this action because installing studio only"
    if [[ $# -gt 0 ]]; then
      info "Reason: $1"
    fi
    return 0
  else
    return 1
  fi
}

function wait_for_user_input_after_server_start() {
  execute_in_container_and_stay "$NUXLPER_NUXEO_CONTAINER_NAME" '
    echo "➡️🚪 Tailing server.log. Press x then Enter to exit"

    tail -F '"$NUXLPER_NUXEO_SERVER_LOG"' &
    tail_pid=$!

    while true; do
      read -r -n1 key
      if [ "$key" = "x" ]; then
        echo -e "\n❌ Exit requested."
        kill "$tail_pid"
        wait "$tail_pid"
        break
      fi
    done
  '
}

# ======================================================================================================================
main "$@"
# ================================== NOTHING BELOW PLEASE!==============================================================
