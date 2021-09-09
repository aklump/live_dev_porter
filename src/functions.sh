#!/usr/bin/env bash

function store_timestamp() {
  local directory="$1"
  rm "$directory/"*.latest.txt 2> /dev/null || true
  touch "$directory/$(date +"%Y-%m-%dT%H.%M.%S%z").latest.txt"
}

#
# Echo the basename of the last pulled database file.
#
function get_path_to_fetched_db() {
  path=$(ls "$PULL_DB_PATH/"*.sql* 2> /dev/null)
  if [[ "$path" ]]; then
    echo "$path"
  fi
}

function delete_last_fetched_db() {
  local dumpfile=$(get_path_to_fetched_db)
  if [[ "$dumpfile" ]]; then
    if [ -f "$dumpfile" ]; then
      rm -v "$dumpfile" || fail_because "Could not delete $dumpfile"
    fi
  fi
  has_failed && return 1
  return 0
}

function get_container_path() {
  local host_path="$1"
  local directory=$(dirname $host_path)

  if [ -d "$host_path" ]; then
    echo $(cd $host_path && lando ssh -c "pwd"|tr -d '\r')
    return 0
  fi

  if [ -f "$host_path" ]; then
    echo $(cd $(dirname "$host_path") && lando ssh -c "pwd"|tr -d '\r')/$(basename "$host_path")
    return 0
  fi

  fail_because "Could not determine container path for "$host_path"" && return 1
  return 0
}

# Call a plugin function.
#
# $1 - The name of the plugin
# $2 - The function name without the plugin leader, so for a function
# called pantheon_fetch_db, you would pass 'fetch_db'.
# $... Additional arguments exclusively will be passed to the plugin function.
#
function call_plugin() {
  local plugin=$1
  local function_tail=$2
  local args=("${@:3}")

  source "$PLUGINS_DIR/$plugin/$plugin.sh"
  if function_exists "${plugin}_${function_tail}"; then
    ${plugin}_${function_tail} "${args[@]}"
  fi
}
