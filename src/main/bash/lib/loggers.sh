#!/bin/bash
########################################################################################################################
#                                               loggers.sh
########################################################################################################################
function info() {
  echo "🪧$*"
}

function ok() {
  echo "👍"
  echo
}

function ok_with_message() {
  echo "👍$*"
  echo
}

function error() {
  if [[ $# -lt 1 ]]; then
    echo "ERROR: missing value to log"
    return 1
  fi
  echo "⛔$1"
}

function error_and_fail() {
  if [[ $# -lt 1 ]]; then
    echo "ERROR: missing value to log"
    return 1
  fi
  error "$@"
  echo "✂️execution is aborted"
  return 1
}

function attempt() {
  echo "🔥Attempt: $*..."
}

function hint() {
  if [[ $# -lt 1 ]]; then
    echo "ERROR: missing value to log"
    return 1
  fi
  echo "💡$1"
}

function log_delete() {
  echo "❌$*"
}

function log_clean() {
  echo "🗑️$*"
}

function log_download() {
  echo "⬇️$*"
}

function log_upload() {
  echo "⬆️$*"
}

function log_install() {
  echo "💻$*"
}
