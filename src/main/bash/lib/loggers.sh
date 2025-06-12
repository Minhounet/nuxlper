#!/bin/bash
########################################################################################################################
#                                               loggers.sh
########################################################################################################################
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
