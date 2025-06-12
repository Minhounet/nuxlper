#!/bin/bash
########################################################################################################################
#                                               docker.sh
########################################################################################################################
function execute_in_container() {
  docker exec "$1" sh -c "$2"
}

function execute_in_container_as_root() {
  docker exec -u root "$1" sh -c "$2"
}

function copy_to_container() {
  docker cp "$2" "$1:$3"
}
