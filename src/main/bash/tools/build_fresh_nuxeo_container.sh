#!/bin/bash
########################################################################################################################
#                                               build_fresh_nuxeo_container.sh
########################################################################################################################
# Set the configuration below:
# - fake smtp docker container
# - Nuxeo docker container with a few modifications to nuxeo.conf based on build_fresh_nuxeo_container.conf.
# Note that jpda is enabled on port 8887!
#
# - docker network for the two containers above.
########################################################################################################################
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC2155
readonly TOOLS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC2155
readonly LIB_DIR=$(dirname "$TOOLS_DIR")/lib
# shellcheck disable=SC2155
readonly CONF_FILENAME="nuxlper.conf"
# shellcheck disable=SC2155
readonly CONF_PATH=$(dirname "$TOOLS_DIR")/$CONF_FILENAME

readonly FAKE_SMTP_IMAGE=haravich/fake-smtp-server
readonly FAKE_SMTP_PORT=1025

readonly SERVER_LOG_READY_PATTERN="= Component Loading Status: Pending: 0 / Missing: 0 / Unstarted: 0"

# Parameters to declare in nuxlper.conf
declare NUXLPER_NUXEO_PROXY_HOST=""
declare NUXLPER_NUXEO_PROXY_PORT=""
declare NUXLPER_NUXEO_IMAGE=""
declare NUXLPER_PULL_NUXEO_IMAGE="y"
declare NUXLPER_NUXEO_SERVER_LOG="/var/log/nuxeo/server.log"

function main() {
  load_executions_lib

  if [[ $# -ge 1 ]]; then
    case "$1" in
      --help|-h) display_help;;
      *) error_and_fail "Unknown command $1" ;;
    esac
    return 0
  fi

  if [[ ! -f $CONF_PATH ]]; then
    error_and_fail "File $CONF_FILENAME is missing, please create it and configure it. $0 --help for more information"
  fi

  load_conf_file
  check_parameters

  pull_fake_smtp_image
  pull_nuxeo_image

  run_new_nuxeo_container
  run_new_fake_smtp_container
  join_containers_in_same_network

  update_nuxeo_conf
  register_nuxeo_instance
  wait_for_server_start
}

# ======================================================================================================================
# Functions
# ======================================================================================================================
function display_help() {
  echo "-------------------------------------------------------------------------------------------------------------"
  echo "$0 build a fresh Nuxeo environment out of the box:
  - build a nuxeo Docker container with a few configuration in nuxeo.conf (such as proxy and jpda
  - build a fake smtp
  - create a network to join them
  "
  echo "-------------------------------------------------------------------------------------------------------------"
  echo "$CONF_FILE must be created and contains the following entries"
  grep  "$0"
}

function load_conf_file() {
  info "Read $CONF_FILENAME"
  # shellcheck disable=SC1090
  source "$CONF_PATH"
  ok
}

function load_executions_lib() {
  source "$LIB_DIR"/executions.sh
}

function check_parameters() {
  attempt "check mandatory parameters"
  require_value "NUXLPER_NUXEO_IMAGE"
  require_value "NUXLPER_NUXEO_CONTAINER_NAME"
  require_value "NUXLPER_FAKE_SMTP_CONTAINER_NAME"
  require_value "NUXLPER_NETWORK_NAME"
  require_value "NUXLPER_SMTP_MAIL_FROM"
  require_value "NUXLPER_NUXEO_INSTANCE_USERNAME"
  require_value "NUXLPER_NUXEO_INSTANCE_TOKEN"
  require_value "NUXLPER_NUXEO_INSTANCE_PROJECT"
  require_value "NUXLPER_NUXEO_INSTANCE_INSTANCE_TYPE"
  require_value "NUXLPER_NUXEO_INSTANCE_DESCRIPTION"
  ok
}

function pull_fake_smtp_image() {
  log_download "Pull fake smtp image"
  docker pull $FAKE_SMTP_IMAGE
  ok
}

function pull_nuxeo_image() {
  log_download "Pull Nuxeo image"
  if [[ "$NUXLPER_PULL_NUXEO_IMAGE" == "y" ]]; then
    docker pull "$NUXLPER_NUXEO_IMAGE"
  else
    info "NUXLPER_PULL_NUXEO_IMAGE not set to \"y\", $NUXLPER_NUXEO_IMAGE will not be pulled and
    will be assumed to be already existing"
  fi
}

# TODO can be extracted to docker.sh but not easy
function run_new_nuxeo_container() {
  attempt "run Nuxeo container"
  if docker ps -a --format '{{.Names}}' | grep -wq "$NUXLPER_NUXEO_CONTAINER_NAME"; then
      echo "A container named '$NUXLPER_NUXEO_CONTAINER_NAME' already exists."
      read -p "🤔Do you want to remove it and start a new one? (y/n): " choice
      if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
          docker rm -f "$NUXLPER_NUXEO_CONTAINER_NAME"
          info "Old container removed. Starting a new one..."
          docker run -d --name "$NUXLPER_NUXEO_CONTAINER_NAME" -e NUXEO_DEV=true -p 8080:8080 -p 8787:8787 "$NUXLPER_NUXEO_IMAGE"
      else
          info "Use existing one"
      fi
  else
      info "No existing container named '$NUXLPER_NUXEO_CONTAINER_NAME'. Starting a new one..."
      docker run -d --name "$NUXLPER_NUXEO_CONTAINER_NAME" -e NUXEO_DEV=true -p 8080:8080 -p 8787:8787 "$NUXLPER_NUXEO_IMAGE"
      ok
  fi
}

function run_new_fake_smtp_container() {
  attempt "run fake smtp container"
  if docker ps -a --format '{{.Names}}' | grep -wq "$NUXLPER_FAKE_SMTP_CONTAINER_NAME"; then
      echo "A container named '$NUXLPER_FAKE_SMTP_CONTAINER_NAME' already exists."
      read -p "🤔Do you want to remove it and start a new one? (y/n): " choice
      if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
          docker rm -f "$NUXLPER_FAKE_SMTP_CONTAINER_NAME"
          info "Old container removed. Starting a new one..."
          docker run -d --name "$NUXLPER_FAKE_SMTP_CONTAINER_NAME" -p 1080:1080 "$FAKE_SMTP_IMAGE"
      else
          info "Use existing one"
      fi
  else
      info "No existing container named '$NUXLPER_FAKE_SMTP_CONTAINER_NAME'. Starting a new one..."
      docker run -d --name "$NUXLPER_FAKE_SMTP_CONTAINER_NAME" -p 1080:1080 "$FAKE_SMTP_IMAGE"
      ok
  fi
}

function join_containers_in_same_network() {
  info "🔗Link containers in same network"
  if docker network ls | grep -wq "$NUXLPER_NETWORK_NAME"; then
    echo "Network already exist, skip this part"
  else
    echo "⛓️Create network and connect fakesmtp with nuxeo container"
    docker network create "$NUXLPER_NETWORK_NAME"
  fi

  for container in $(docker network inspect -f '{{range $id, $container := .Containers}}{{$container.Name}} {{end}}' $NUXLPER_NETWORK_NAME); do
    docker network disconnect "$NUXLPER_NETWORK_NAME" "$container"
  done
  echo "⛓️Link $NUXLPER_FAKE_SMTP_CONTAINER_NAME with $NUXLPER_NUXEO_CONTAINER_NAME in $NUXLPER_NETWORK_NAME"
  docker network connect "$NUXLPER_NETWORK_NAME" "$NUXLPER_FAKE_SMTP_CONTAINER_NAME"
  docker network connect "$NUXLPER_NETWORK_NAME" "$NUXLPER_NUXEO_CONTAINER_NAME"
  ok
}

function update_nuxeo_conf() {
  echo "🪛Update nuxeo.conf"
  if [[ -n "$NUXLPER_NUXEO_PROXY_HOST" ]]; then
    info "NUXLPER_NUXEO_PROXY_HOST is defined, set proxy/port in nuxeo conf file"
    # TODO can be extracted to nuxeo.sh
    docker exec "$NUXLPER_NUXEO_CONTAINER_NAME" bash -c '
      CONF_FILE="/etc/nuxeo/nuxeo.conf"
      # Set proxy host
         if grep -q "^#\?nuxeo.http.proxy.host=" "$CONF_FILE"; then
           sed -i "s|^#\?nuxeo.http.proxy.host=.*|nuxeo.http.proxy.host='"$NUXLPER_NUXEO_PROXY_HOST"'|" "$CONF_FILE"
         else
           echo "nuxeo.http.proxy.host='"$NUXLPER_NUXEO_PROXY_HOST"'" >> "$CONF_FILE"
         fi

         # Set proxy port
         if grep -q "^#\?nuxeo.http.proxy.port=" "$CONF_FILE"; then
           sed -i "s|^#\?nuxeo.http.proxy.port=.*|nuxeo.http.proxy.port='"$NUXLPER_NUXEO_PROXY_PORT"'|" "$CONF_FILE"
         else
           echo "nuxeo.http.proxy.port='"$NUXLPER_NUXEO_PROXY_PORT"'" >> "$CONF_FILE"
         fi
     '
  fi

  docker exec "$NUXLPER_NUXEO_CONTAINER_NAME" bash -c '
    CONF_FILE="/etc/nuxeo/nuxeo.conf"

    # Enable developer mode
    if grep -q "^#\?org.nuxeo.dev=" "$CONF_FILE"; then
      sed -i "s/^#\?org.nuxeo.dev=.*/org.nuxeo.dev=true/" "$CONF_FILE"
    else
      echo "org.nuxeo.dev=true" >> "$CONF_FILE"
    fi

    # smtp
    if grep -q "^#\?mail.transport.host=" "$CONF_FILE"; then
      sed -i "s|^#\?mail.transport.host=.*|mail.transport.host='"$NUXLPER_FAKE_SMTP_CONTAINER_NAME"'|" "$CONF_FILE"
    else
      echo "mail.transport.host='"$NUXLPER_FAKE_SMTP_CONTAINER_NAME"'" >> "$CONF_FILE"
    fi

    if grep -q "^#\?mail.transport.port=" "$CONF_FILE"; then
      sed -i "s|^#\?mail.transport.port=.*|mail.transport.port='"$FAKE_SMTP_PORT"'|" "$CONF_FILE"
    else
      echo "mail.transport.port='"$FAKE_SMTP_PORT"'" >> "$CONF_FILE"
    fi

    if grep -q "^#\?mail.from=" "$CONF_FILE"; then
      sed -i "s|^#\?mail.from=.*|mail.from='"$NUXLPER_SMTP_MAIL_FROM"'|" "$CONF_FILE"
    else
      echo "mail.from='"$NUXLPER_SMTP_MAIL_FROM"'" >> "$CONF_FILE"
    fi
  '
  ok
}

function register_nuxeo_instance() {
  echo "✒️Register nuxeo instance on connect.nuxeo.com"
  docker exec "$NUXLPER_NUXEO_CONTAINER_NAME"  bash -c '
  echo '"$NUXLPER_NUXEO_INSTANCE_USERNAME"' >> /tmp/peppa
  echo '"$NUXLPER_NUXEO_INSTANCE_TOKEN"' >> /tmp/peppa
  echo '"$NUXLPER_NUXEO_INSTANCE_PROJECT"' >> /tmp/peppa
  echo '"$NUXLPER_NUXEO_INSTANCE_INSTANCE_TYPE"' >> /tmp/peppa
  echo '"$NUXLPER_NUXEO_INSTANCE_DESCRIPTION"' >> /tmp/peppa
  cat /tmp/peppa
  /opt/nuxeo/server/bin/nuxeoctl register < /tmp/peppa
  rm -rf /tmp/peppa
  '
  ok
}

function wait_for_server_start() {
  echo "⏳Waiting for Nuxeo to fully start..."
  docker exec -i "$NUXLPER_NUXEO_CONTAINER_NAME" bash -c "
    tail -F $NUXLPER_NUXEO_SERVER_LOG | while read line; do
      echo \"\$line\"
      if echo \"\$line\" | grep -q \"$SERVER_LOG_READY_PATTERN\"; then
        echo '✅ Nuxeo has fully started.'
        break
      fi
    done
  "
  ok
}

# ======================================================================================================================
main "$@"
# ================================== NOTHING BELOW PLEASE!==============================================================