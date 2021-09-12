#!/usr/bin/env bash

# Store a timestamp file.
#
# Use yaml_add_line to augment the stored contents.
#
# $1 - The path to the directory where to write the file.
#
function store_timestamp() {
  local directory="$1"
  rm "$directory/"*.latest.txt 2> /dev/null || true

  local timestamp=$(date +"%Y-%m-%dT%H.%M.%S%z")
  yaml_add_line "date: $(date +"%b %d, %Y at %I:%M %p")"
  yaml_add_line "elapsed: $(echo_elapsed)"
  yaml_get > "$directory/${timestamp}.latest.txt"
  yaml_clear
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

  [ -f "$PLUGINS_DIR/$plugin/$plugin.sh" ] || return 1
  source "$PLUGINS_DIR/$plugin/$plugin.sh"
  if function_exists "${plugin}_${function_tail}"; then
    ${plugin}_${function_tail} "${args[@]}"
  fi
}

function plugin_implements() {
  local plugin=$1

  [ -f "$PLUGINS_DIR/$plugin/$plugin.sh" ] || return 1
  source "$PLUGINS_DIR/$plugin/$plugin.sh"
  function_exists "${plugin}_$2"
}

function implement_route_access() {
  command=$(get_command)
  eval $(get_config_as 'allowed_routes' "commands.$command.access_by_env")
  [[ "" == "$allowed_routes" ]] && return 0

  local csv
  for i in "${allowed_routes[@]}"; do
     [ "$i" == "$LOCAL_ENV_ID" ] && return 0
     eval $(get_config_as env_alias "environments.$i.id")
     csv="$csv, \"$env_alias\""
  done

  fail_because "\"$command\" can be used only in ${csv#, } environments."
  fail_because "Current environment is \"$LOCAL_ENV\"."
  exit_with_failure "Command not allowed"
}
