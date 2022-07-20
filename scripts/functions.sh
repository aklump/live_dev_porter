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

# Echo a validated workflow ID for a given command.
#
# $1 - The command
#
# @code
# ! WORKFLOW_ID=$(get_workflow_by_command 'export') && fail_because "$WORKFLOW_ID" && exit_with_failure
# @endcode
#
# Returns 0 if and echos workflow ID; returns 1 if no workflow found.
function get_workflow_by_command() {
  local command="$1"

  local id
  eval $(get_config_as "id" "environments.$LOCAL_ENV_ID.command_workflows.$command")
  [[ ! "$id" ]] && return 0
  ! id=$(validate_workflow "$id") && echo "$id" && return 1
  echo "$id" && return 0
}

# Ensure a given workflow ID is valid.
#
# $1 - A workflow ID.
#
# Returns 0 and echos the ID if valid; otherwise echo error and return 1
function validate_workflow() {
  local workflow_id="$1"

  eval $(get_config_keys_as array_has_value__array "workflows")
  array_has_value "$workflow_id" && echo "$workflow_id" && return 0
  echo "\"$workflow_id\" is not a configured workflow."
  return 1
}

# All pass-through variables must be set prior to calling.
#
# $1 - the workflow ID.
#
# Returns 0 if .
function execute_workflow_processors() {
  local workflow="$1"

  local processor
  local processor_path
  local processor_output
  local processor_result
  local key
  local php_query

  eval $(get_config_keys_as workflow_keys "workflows.$workflow")
  for workflow_key in "${workflow_keys[@]}"; do
    eval $(get_config_as basename "workflows.$workflow.$workflow_key.processor")
    [[ ! "$basename" ]] && continue

    processor_path="$CONFIG_DIR/processors/$basename"
    processor="$(path_unresolve "$APP_ROOT" "$processor_path")"

    if [[ "$(path_extension "$processor_path")" == "sh" ]]; then
      [[ ! -f "$processor_path" ]] && fail_because "Missing file processor: $processor" && return 1
      echo_task "$(path_unresolve "$CONFIG_DIR" "$processor_path")"
      processor_output=$(cd $APP_ROOT; source "$SOURCE_DIR/processor_support.sh"; . "$processor_path")
      processor_result=$?
    else
      php_query="autoload=$CONFIG_DIR/processors/&COMMAND=$COMMAND&ENVIRONMENT_ID=$ENVIRONMENT_ID&DATABASE_ID=$DATABASE_ID&DATABASE_NAME=$DATABASE_NAME&FILES_GROUP_ID=$FILES_GROUP_ID&FILEPATH=$FILEPATH&SHORTPATH=$SHORTPATH&IS_WRITEABLE_ENVIRONMENT=$IS_WRITEABLE_ENVIRONMENT"
      echo_task "$(path_unresolve "$CONFIG_DIR" "$processor_path")"
      processor_output=$(cd $APP_ROOT; export CLOUDY_CONFIG_JSON; $CLOUDY_PHP "$ROOT/php/class_method_caller.php" "$basename" "$php_query")
      processor_result=$?
    fi

    if [[ $processor_result -eq 255 ]]; then
      clear_task
    elif [[ $processor_result -ne 0 ]]; then
      echo_task_failed
      [[ "$processor_output" ]] && fail_because "$processor_output"
      if [[ "$FILES_GROUP_ID" ]]; then
        fail_because "\"$processor\" has failed while processing: $SHORTPATH (in files group \"$FILES_GROUP_ID\")."
      else
        fail_because "\"$processor\" has failed while processing database: $DATABASE_ID."
      fi
      return 1
    else
      echo_task_completed
      [[ "$processor_output" ]] && succeed_because "$processor_output"
    fi
  done

  return 0
}

# Call a plugin function.
#
# If the named plugin doesn't support the function, the "default" plugin will be tried.
#
# $1 - The name of the plugin
# $2 - The function name without the plugin leader, so for a function
# called pantheon_on_fetch_db, you would pass 'fetch_db'.
# $... Additional arguments exclusively will be passed to the plugin function.
#
function call_plugin() {
  local plugin=$1
  local function_tail=$2
  local args=("${@:3}")

  local func_name
  func_name=$(_plugin_get_func_name "$plugin" "$function_tail")
  ! plugin_implements $plugin $function_tail && fail_because "Plugin \"$plugin\" does not define a function called $func_name()" && return 1
  $func_name "${args[@]}"
}

function _plugin_get_func_name() {
  local plugin=$1
  local function_tail=$2

  echo "${plugin}_on_${function_tail}"
}

# Test if a given plugin implements a hook.
#
# $1 - The plugin name.
# $2 - The hook base, e.g. 'pull_db'.  Will look for PLUGIN_on_pull_db().
#
# Returns 0 if .
function plugin_implements() {
  local plugin=$1
  local function_tail=$2

  [ -f "$PLUGINS_DIR/$plugin/$plugin.sh" ] || return 1
  source "$PLUGINS_DIR/$plugin/$plugin.sh"
  function_exists "$(_plugin_get_func_name "$plugin" "$function_tail")"
}

function implement_route_access() {
  command=$(get_command)

  local access

  eval $(get_config_as require_remote "commands.${command}.require_remote_env")
  eval $(get_config_as require_write "commands.${command}.require_write_access")
  # No special perms required.
  [[ "$require_write" != true ]] && [[ "$require_remote" != true ]] && return 0

  eval $(get_config_as write_access "environments.$LOCAL_ENV_ID.write_access")
  eval $(get_config_as remote "remote")

  if [[ "$require_write" == true ]] && [[ "$write_access" != true ]]; then
    fail_because "write_access is false for this environment ($LOCAL_ENV_ID)."
    fail_because "set to true in the configuration, to allow this command."
  fi
  if [[ "$require_remote" == true ]] && [[ "$remote" == null ]]; then
    fail_because "This command requires a remote environment be configured."
  fi
  has_failed && exit_with_failure "\"$command\" not allowed in this environment."
  return 0
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

function echo_red_path_if_nonexistent() {
  local path="$1"

  if [[ ! -e "$path" ]]; then
    echo_red "$path"
  else
    echo "$path"
  fi
}

# Sets the process priority as low as possible to not affect server performance.
#
# Returns nothing.
#
# @see man ionice for more info
# @link https://www.tutorialspoint.com/unix_commands/ionice.htm
# @link https://www.tiger-computing.co.uk/linux-tips-nice-and-ionice/
function process_in_the_background {
  which ionice >/dev/null || return

  ionice -c 2 -n 7 -p $BASHPID >/dev/null
  renice  +10 -p  $BASHPID >/dev/null
}
