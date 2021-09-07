#!/usr/bin/env bash

function store_timestamp() {
  local directory="$1"
  rm "$directory/"*.latest.txt 2> /dev/null || true
  touch "$directory/$(date +"%Y-%m-%dT%H.%M.%S%z").latest.txt"
}

#
# Echo the basename of the last pulled database file.
#
function get_pulled_db_basename() {
  path=$(ls "$PULL_DB_PATH")
  if [[ "$path" ]]; then
    echo "$path"
  fi
}

function delete_pulled_db() {
  local basename=$(get_pulled_db_basename)
  if [[ "$basename" ]]; then
    path="$PULL_DB_PATH/$(get_pulled_db_basename)"
    if [ -f "$path" ]; then
      rm -v "$path" || fail_because "Could not delete $path"
    fi
  fi
  has_failed && exit_with_failure
}

function plugin_reset_db() {
  (cd "$PULL_DB_PATH" && lando db-import "$(get_pulled_db_basename)")
}

function plugin_reset_files() {
  rsync -av "$PULL_FILES_PATH/" "$ROOT_DIR/)"
}

function get_container_path() {
  local host_path="$1"

  echo $(cd $host_path && lando ssh -c "pwd"|tr -d '\r')
}
