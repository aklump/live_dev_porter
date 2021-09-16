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
  local function="${plugin}_${function_tail}"
  ! function_exists $function && fail_because "Plugin \"$plugin\" does not support \"$function_tail\"" && return 1
  $function "${args[@]}"
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

# Echo the ssh user@host string for the remote environment.
#
function get_remote() {
  eval $(get_config_as remote_user "environments.$REMOTE_ENV_ID.ssh.user")
  exit_with_failure_if_empty_config remote_user "environments.$REMOTE_ENV_ID.ssh.user"
  eval $(get_config_as remote_host "environments.$REMOTE_ENV_ID.ssh.host")
  exit_with_failure_if_empty_config remote_host "environments.$REMOTE_ENV_ID.ssh.host"
  echo "$remote_user@$remote_host"
}

# Echo the local part of a file path config value.
#
# $1 - A string in this pattern PATH or LOCAL:REMOTE or LOCAL REMOTE. Be sure to
# wrap in double quotes or this may fail.
#
# @code
#   local local_path=$(combo_path_get_local "$subdir")
# @endcode
#
function combo_path_get_local() {
  local data=$1

  parts=(${data/:/ })
  echo ${parts[0]}
}

# Echo the remote part of a file path config value.
#
# $1 - A string in this pattern PATH or LOCAL:REMOTE or LOCAL REMOTE. Be sure to
# wrap in double quotes or this may fail.
#
# @code
#   local remote_path=$(combo_path_get_remote "$subdir")
# @endcode
function combo_path_get_remote() {
  local data=$1

  parts=(${data/:/ })
  local remote=${parts[1]}
  if [[ "$remote" ]]; then
    echo $remote
  else
    echo ${parts[0]}
  fi
}

# Make sure all file_sync local directories and files are created.
#
# Returns 0 if successful, 1 otherwise.
function ensure_files_sync_local_directories() {
  if [[ ! "$FETCH_FILES_PATH" ]]; then
    fail_because "FETCH_FILES_PATH cannot be empty" && return 1
  fi

  # Create the base directories and the exclude-from files.
  eval $(get_config_keys_as -a sync_groups files_sync)
  for group in "${sync_groups[@]}"; do
    [ -d "$FETCH_FILES_PATH/$group" ] || mkdir -p "$FETCH_FILES_PATH/$group" || fail
    touch "$FETCH_FILES_PATH/$group.ignore.txt" || fail
  done
}
