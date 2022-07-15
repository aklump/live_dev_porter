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

# Gets the active workflow by command or --workflow.
#
# Returns 1 if invalid workflow.  Echos the workflow ID, if valid and present.
function get_active_workflow() {
  local workflow=$(get_option 'workflow')
  if [[ ! "$workflow" ]]; then
    eval $(get_config_as "workflow" "environments.$LOCAL_ENV_ID.command_workflows.$COMMAND")
  fi

  # If there is no workflow, then all is well.
  [[ ! "$workflow" ]] && return 0
  eval $(get_config_keys_as array_has_value__array "workflows")

  # Ensure is a configured workflow...
  array_has_value "$workflow" && echo "$workflow" && return 0

  # ... otherwise fail.
  echo "\"$workflow\" is not a configured workflow."
  return 1
}

function execute_workflow_processors() {
  local workflow="$1"

  local processor
  local processor_path
  local processor_output
  local processor_result
  local key
  local php_query
  local DATABASE_NAME
  if [[ "$ENVIRONMENT_ID" ]] && [[ "$DATABASE_ID" ]]; then
    DATABASE_NAME="$(mysql_get_env_db_name_by_id $ENVIRONMENT_ID $DATABASE_ID)" || DATABASE_NAME=''
  fi

  if [[ "$DATABASE_NAME" ]]; then
    # These should never hold values if we are processing a database.
    FILES_GROUP_ID=''
    FILEPATH=''
    SHORTPATH=''
  else
    # Without a name, we should never have an ID.
    DATABASE_ID=''
  fi

  eval $(get_config_keys_as workflow_keys "workflows.$workflow")
  for workflow_key in "${workflow_keys[@]}"; do
    eval $(get_config_as basename "workflows.$workflow.$workflow_key.processor")
    [[ ! "$basename" ]] && continue

    processor_path="$CONFIG_DIR/processors/$basename"
    processor="$(path_unresolve "$APP_ROOT" "$processor_path")"

    if [[ "$(path_extension "$processor_path")" == "sh" ]]; then
      [[ ! -f "$processor_path" ]] && fail_because "Missing file processor: $processor" && return 1
      processor_output=$(cd $APP_ROOT; source "$SOURCE_DIR/processor_support.sh"; . "$processor_path")
      processor_result=$?
    else
      php_query="autoload=$CONFIG_DIR/processors/&COMMAND=$COMMAND&ENVIRONMENT_ID=$ENVIRONMENT_ID&DATABASE_ID=$DATABASE_ID&DATABASE_NAME=$DATABASE_NAME&FILES_GROUP_ID=$FILES_GROUP_ID&FILEPATH=$FILEPATH&SHORTPATH=$SHORTPATH"
      processor_output=$(cd $APP_ROOT; export CLOUDY_CONFIG_JSON; $CLOUDY_PHP "$ROOT/php/class_method_caller.php" "$basename" "$php_query")
      processor_result=$?
    fi

    if [[ $processor_result -ne 0 ]]; then
      [[ "$processor_output" ]] && fail_because "$processor_output"
      if [[ "$FILES_GROUP_ID" ]]; then
        fail_because "\"$processor\" has failed while processing: $SHORTPATH (in files group \"$FILES_GROUP_ID\")."
      else
        fail_because "\"$processor\" has failed while processing database: $DATABASE_ID."
      fi
      return 1
    fi
    succeed_because "$processor_output"
  done

  return 0
}

# Call a plugin function.
#
# If the named plugin doesn't support the function, the "default" plugin will be tried.
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

  local function
  [ -f "$PLUGINS_DIR/$plugin/$plugin.sh" ] || return 1
  source "$PLUGINS_DIR/$plugin/$plugin.sh"
  function="${plugin}_${function_tail}"
  if ! function_exists $function; then
    function="default_${function_tail}"
  fi
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

  eval $(get_config_as write_access "environments.$LOCAL_ENV_ID.write_access")
  [[ $write_access == true ]] && return 0

  fail_because "write_access is false for this environment ($LOCAL_ENV_ID)."
  fail_because "set to true in the configuration, to allow this command."
  exit_with_failure "\"$command\" not allowed"
}

# Resolve an environment relative path to absolute
#
# $1 - The environment ID.
# $2 - The relative path.
#
# Returns 0 if successful. 1 if failed. Echos the absolute path.
function environment_path_resolve() {
  local environment_id="$1"
  local path="$2"

  [[ '/' == "${path:0:1}" ]] &&  echo "The path argument must not begin with /" && return 1

  eval $(get_config_path_as base_path "environments.$environment_id.base_path")
  [[ ! "$base_path" ]] && echo "Missing config for: environments.$environment_id.base_path" && return 1
  path_resolve "$base_path" "$path"
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
  eval $(get_config_path -a "additional_config")
  [[ ${#additional_config[@]} -eq 0 ]] && return 0

  local message
  echo_heading "Core"
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

#
# If you use ssh -o “BatchMode yes”, then it will do ssh only if the
# password-less login is enabled, else it will return error and continues.
# $1 -
#
# Returns 0 if .
function remote_ssh() {
  ssh -t -o BatchMode=yes "$REMOTE_ENV_AUTH" $@
}

function echo_time_heading() {
  echo "$LIL $(time_local)"
}
