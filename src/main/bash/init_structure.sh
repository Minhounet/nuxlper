#!/usr/bin/env bash

# shellcheck disable=SC2155
readonly CURRENT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

########################################################################################################################
# Entry point
########################################################################################################################
function main() {
  source "$CURRENT_DIR/lib/loggers.sh"
  cd "$CURRENT_DIR" || return 1

  if [[ $# -ge 1 && "$1" == "--clean" ]]; then
    clean
    return $?
  fi

  info "This script create a structure (example) to work with a Nuxeo dev."
  local go_on
  read -rp "Do you want to continue ? " go_on
  go_on=${go_on:-y}

  if [[ "$go_on" != "y" ]]; then
    info "Action is cancelled, exit execution"
    return 0
  fi

  info "Build structure"
  link_needed_scripts
  generate_post_install_script
  generate_install_all_script
  generate_nuxeo_hot_reload_script
  generate_install_studio_only_script
  generate_conf_file
}
########################################################################################################################
# Functions
########################################################################################################################
function generate_install_studio_only_script() {
  info "Generate install studio only script"
  echo "#!/usr/bin/env bash
tools/install_nuxeo_items.sh --studio-only" > 05_nuxeo_install_studio_only.sh
    chmod 755 05_nuxeo_install_studio_only.sh
}


function generate_nuxeo_hot_reload_script() {
  info "Generate Nuxeo hot reload script"
  echo "#!/usr/bin/env bash
tools/install_nuxeo_items.sh --reload
" > 04_nuxeo_hot_reload.sh
  chmod 755 04_nuxeo_hot_reload.sh
}

function link_needed_scripts() {
   info "Get $CURRENT_DIR/tools/build_fresh_nuxeo_container.sh "
   ln -sf "$CURRENT_DIR"/tools/build_fresh_nuxeo_container.sh 01_build_fresh_nuxeo_container.sh
   info "Get $CURRENT_DIR/tools/install_nuxeo_items.sh"
   ln -sf "$CURRENT_DIR"/tools/install_nuxeo_items.sh  02_install_nuxeo_items.sh
}

function generate_conf_file() {
  if [[ ! -f  "$CURRENT_DIR/nuxlper.conf" ]]; then
    cat "$CURRENT_DIR"/templates/nuxlper.conf.build_fresh_nuxeo_container > nuxlper.conf
    cat "$CURRENT_DIR"/templates/nuxlper.conf.install_nuxeo_items >> nuxlper.conf
  fi
}

function generate_post_install_script() {
  info "Generate post install script"
  if [[ -f 03_post_install.sh ]]; then
    info "03_post_install.sh already exist, don't create it"
    return 0
  fi
  echo "#!/usr/bin/env bash
  # Write post install script for Nuxeo !" > 03_post_install.sh
  chmod 755 03_post_install.sh
}

function generate_install_all_script() {
  # shellcheck disable=SC2016
  echo '
source '"$CURRENT_DIR"'/nuxlper.conf
./01_build_fresh_nuxeo_container.sh

max_attempts=5
attempt=1

while [ $attempt -le $max_attempts ]; do
  echo "🚀 Attempt $attempt of $max_attempts to run 02_install_nuxeo_items.sh..."
  ./02_install_nuxeo_items.sh
  return_code=$?

  case $return_code in
    0|130)
      echo "✅ Script ended cleanly (code: $return_code)."
      break
      ;;
    *)
      echo "⚠️ Script failed with code $return_code."
      echo "Hint: see logs using:
      docker logs $NUXLPER_NUXEO_CONTAINER_NAME"

      echo "🔁 Attempting to restart container if needed..."
      docker start $NUXLPER_NUXEO_CONTAINER_NAME >/dev/null 2>&1 || true

      attempt=$((attempt + 1))
      if [ $attempt -gt $max_attempts ]; then
        echo "❌ Maximum attempts reached. Installation failed with code $return_code."
        exit $return_code
      else
        echo "⏳ Retrying in 5 seconds..."
        sleep 5
      fi
      ;;
  esac
done

./03_post_install.sh
' > 00_install_all.sh

  chmod 755 00_install_all.sh
}


function clean() {
  local go_on=n
  info "About to delete structure."
  read -rp "Are you sure?" go_on
  go_on=${go_on:-n}
  if [[ "$go_on" == "n" ]]; then
    info "action is cancelled"
    return 0;
  fi
  rm -rf 00_install_all.sh 01_build_fresh_nuxeo_container.sh 02_install_nuxeo_items.sh
  info "03_post_install.sh and nulxper.conf are not removed, please remove it by yourself if needed"
}

########################################################################################################################
main "$@"
# Nothing below please
########################################################################################################################
