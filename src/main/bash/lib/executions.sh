#!/bin/bash
########################################################################################################################
#                                               executions.sh
########################################################################################################################
# shellcheck disable=SC2155
readonly EXECUTIONS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$EXECUTIONS_DIR"/loggers.sh

function require_value() {
  if [[ $# -lt 1 ]]; then
    error_and_fail "missing value when calling require_value"
    return 1
  fi
  set +o nounset
  local var_name="$1"
  local var_value="${!var_name}"
  attempt "reading $var_name"
  if [[ -z "$var_value" ]]; then
    error_and_fail "$var_name cannot be empty"
  fi
  set -o nounset
  ok
}

function load_nuxeo_lib() {
  source "$EXECUTIONS_DIR"/nuxeo.sh
}
function load_loggers_lib() {
  source "$EXECUTIONS_DIR/loggers.sh"
}
function load_docker_lib() {
  source "$EXECUTIONS_DIR/docker.sh"
}

