#!/bin/bash
########################################################################################################################
#                                               nuxeo.sh
########################################################################################################################
# shellcheck disable=SC2155
readonly NUXEO_SCRIPT_DIR=$(dirname "$(realpath "$0")")
readonly NUXEO_ADMIN_CREDENTIALS=${NUXLPER_ADMIN_CREDENTIALS:-Administrator:Administrator}
readonly NUXEO_COMMAND_HOT_RELOAD="curl -X POST 'http://localhost:8080/nuxeo/site/automation/Service.HotReloadStudioSnapshot' \
-H 'Nuxeo-Transaction-Timeout: 30' -H 'X-NXproperties: *' -H 'X-NXRepository: default' -H 'X-NXVoidOperation: false' \
-H 'content-type: application/json' -d '{\"params\":{\"validate\":true},\"context\":{}}' -u ${NUXEO_ADMIN_CREDENTIALS}"

source "$NUXEO_SCRIPT_DIR"/loggers.sh

function perform_nuxeo_hot_reload() {
  local max_retries=5
  local attempt=1
  local success=0

  while [ $attempt -le $max_retries ]; do
    attempt "🔥 Attempt $attempt: Performing Nuxeo hot reload..."
    result="$(eval "${NUXEO_COMMAND_HOT_RELOAD}")"
    echo "$result"

    if echo "${result}" | grep -q "Studio package installed"; then
      ok_with_message "Studio package installed successfully."
      success=1
      break
    else
      error "Studio package not installed. Retrying..."
      ((attempt++))
      sleep 2
    fi
  done
  if [ $success -eq 0 ]; then
    error_and_fail "Failed to detect 'Studio package installed' after $max_retries attempts."
  fi
}
