#!/bin/bash
########################################################################################################################
#                                               loggers.sh
########################################################################################################################
function ok() {
  echo "👍"
  echo
}

function _echo() {
  if [[ $# -lt 1 ]]; then
    echo "ERROR: missing value to log"
    return 1
  fi
  echo "$1"
}

function hint() {
  if [[ $# -lt 1 ]]; then
    echo "ERROR: missing value to log"
    return 1
  fi
  echo "💡$1"
}

function error() {
  if [[ $# -lt 1 ]]; then
    echo "ERROR: missing value to log"
    return 1
  fi
  echo "⛔$1"
}
