#!/usr/bin/env bash

# Ensure a directory is within the $APP_ROOT.
#
# This should be called before any write operations to the file system as it
# will make sure the directory is within the app, which is assumed to be safe.
#
# Will exit_with_failure if the directory is not safe.
#
# @code
# sandbox_directory "$destination_base/foo"
# rm -r "$destination_base/foo"
# @endcode
#
# Returns nothing.
function sandbox_directory() {
  local dir="$1"
  ! [[ "$APP_ROOT" ]] && fail_because '$APP_ROOT was empty'
  ! [[ -d "$APP_ROOT" ]] && fail_because "$APP_ROOT does not exist"
  ! [[ "$dir" ]] && fail_because "The directory is an empty value."
  local unresolved="$(path_unresolve "$APP_ROOT" "$dir")"
  [[ "$dir" == "$unresolved" ]] && fail_because "The directory $dir must be within $APP_ROOT"
  has_failed && exit_with_failure
}

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

  eval $(get_config_as requirement "commands.${command}.require_write_access")
  [[ ! "$requirement" ]] && return 0
  [[ false == "$requirement" ]] && return 0

  eval $(get_config_as write_access "environments.${LOCAL_ENV_LOOKUP}.write_access")
  [[ $write_access == true ]] && return 0

  fail_because "write_access is false for this environment ($LOCAL_ENV_ID)."
  fail_because "set to true in the configuration, to allow this command."
  exit_with_failure "\"$command\" not allowed"
}

# Echo authorization portion of a path, e.g. user@host.
#
# $1 - The environment id, e.g. dev, production
function echo_env_auth() {
  local env_id=$1

  eval $(get_config_as user "environments.$env_id.user")
  exit_with_failure_if_empty_config user "environments.$env_id.user"
  eval $(get_config_as host "environments.$env_id.host")
  exit_with_failure_if_empty_config host "environments.$env_id.host"
  echo "$user@$host"
}

# Echo a path resolved to an environment base path.
#
# $1 - The environment id, e.g. dev, production.
# $2 - Relative path to be resolved to the environment base.  Omit this to
# return the environment base path itself.
#
# Returns 1 if the path is absolute.
function path_relative_to_env() {
  local env_id="$1"
  local path="$2"

  if [[ '/' == "${path:0:1}" ]]; then
    fail_because "The path argument must not begin with /"
    return 1
  fi

  local base_path
  if [[ "$env_id" == "$LOCAL_ENV_ID" ]]; then
    base_path="$APP_ROOT"
  else
    eval $(get_config_as "base_path" "environments.$env_id.base_path")
    if [[ ! "$base_path" ]]; then
      fail_because "Missing configuration value for environments.$env_id.base_path"
      return 1
    fi
  fi

  echo "$(path_resolve "$base_path" "$path")"
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

function implement_configtest() {
  echo_heading "Core"

  eval $(get_config_path -a "additional_config")
  local message
  for i in "${additional_config[@]}"; do
    message="Configuration file exists: $(basename "$i")"
    if [ -e "$i" ]; then
      echo_pass "$message"
    else
      echo_fail "$message" && fail
    fi
  done
  has_failed && fail_because "Use 'init' to create configuration files"
}
