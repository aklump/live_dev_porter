#!/usr/bin/env bash


##
 # Check if a directory has been initialized for Live Dev Porter.
 #
 # @param string The path to the directory to check
 #
 # @return 0 If it's been initialized
 # @return 1 If not.
 ##
function ldp_dir_is_initialized() {
  local directory="$1/.$CLOUDY_PACKAGE_ID/"

  # @see init_resources/cloudy_init_rules.yml for directory composition.
  [ ! -e "$directory" ] && return 1

  # Make sure we rtrim all slashes or our comparisons below will fail.
  directory=${directory%%/}

  # Scan the config directory for any files that indicate it's already been
  # initialized, we're very conservative looking for any unknown file, rather
  # than looking for known files.  This will be safer if things change over
  # time in that projects are less likely to get reinitialized.
  local _installation_basedir="$CLOUDY_BASEPATH/.$CLOUDY_PACKAGE_ID"
  local _cache_subpath="$(path_make_relative "$CLOUDY_CACHE_DIR" "$_installation_basedir")"
  local _ignored_cache_dir="$directory/${_cache_subpath%%/}"

  [[ -e "$directory" ]] && _contents=$(find "$directory" -mindepth 1 -maxdepth 1 ! -path "$_ignored_cache_dir" ! -name .DS_Store)
  ! [[ -z "${_contents// }" ]] && return 0
  return 1
}

#
# @see class_method_caller.php
# @see call_php_class_method_echo_or_fail for another version.
#
# @code
# call_php_class_method "\AKlump\LiveDevPorter\Config\SchemaBuilder::build" "CACHE_DIR=$CACHE_DIR"
# @endcode
#
# Returns 0 if successful.  Non-zero otherwise.
function call_php_class_method() {
  local callback="$1"
  local serialized_args="$2"

  . "$PHP_FILE_RUNNER" "$ROOT/php/class_method_caller.php" "$callback" "$serialized_args"
}

# Call a php class method AND set success/failure status and messaging.
#
# @see class_method_caller.php
# @see call_php_class_method for a non outputting version.
#
# Returns 0 if successful.  Non-zero otherwise.
function call_php_class_method_echo_or_fail() {
  local callback="$1"
  local serialized_args="$2"

  message="$(. "$PHP_FILE_RUNNER" "$ROOT/php/class_method_caller.php" "$callback" "$serialized_args" "${@:3}")"
  status=$?
  if [[ $status -ne 0 ]]; then
    fail_because "$message"
    exit_with_failure --status=$status "$callback() failed."
  elif [[ "$message" ]]; then
    succeed_because "$message"
  fi
}

# Echo the return value of a php class method
#
# $1 - The PHP class (not-static) method, e.g. "\SchemaBuilder::build".
# $2 - An encoded query string.  This will be passed to the class constructor
# as the first argument.  Note: The class constructor will receive cloudy config
# as the second argument; see caller.php for more info.
#
# Returns 0 if .
function echo_php_class_method() {
  local callback="$1"
  local serialized_args="$2"

  . "$PHP_FILE_RUNNER" "$ROOT/php/class_method_caller.php" "$callback" "$serialized_args" "${@:3}"
}

# Ensure a directory is within the $CLOUDY_BASEPATH.
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

  # This will resolve relative links if the directory exists.  Unresolved
  # relative links will fail sandboxing.
  [[ -d "$dir" ]] && dir="$(cd $1 && pwd)"

  ! [[ "$CLOUDY_BASEPATH" ]] && fail_because '$CLOUDY_BASEPATH was empty'
  ! [[ -d "$CLOUDY_BASEPATH" ]] && fail_because "\$CLOUDY_BASEPATH does not exist"
  ! [[ "$dir" ]] && fail_because "The directory is an empty value."
  local unresolved="$(path_make_relative "$dir" "$CLOUDY_BASEPATH")"
  [[ "$dir" == "$unresolved" ]] && fail_because "The directory \"$dir\" must be within \$CLOUDY_BASEPATH"
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
  [[ "$id" == null ]] && return 0
  ! id=$(validate_workflow "$id") && echo "$id" && return 1
  echo "$id" && return 0
}

# Ensure a given environment ID is valid.
#
# $1 - A environment ID.
#
# @code
# ! id=$(validate_workflow "$id") && echo "$id" && return 1
# echo "$id" && return 0
# @endcode
#
# Returns 0 and echos the ID if valid; otherwise echo error and return 1
function validate_workflow() {
  local workflow_id="$1"

  eval $(get_config_keys_as array_has_value__array "workflows")
  array_has_value "$workflow_id" && echo "$workflow_id" && return 0
  echo "\"$workflow_id\" is not a configured workflow."
  return 1
}

# Ensure a given database ID is valid for the local environment.
#
# $1 - A database ID.
#
# @code
# ! id=$(validate_workflow "$id") && echo "$id" && return 1
# echo "$id" && return 0
# @endcode
#
# Returns 0 and echos the ID if valid; otherwise echo error and return 1
function validate_local_database_id() {
  local database_id="$1"

  eval $(get_config_keys_as array_has_value__array "environments.$LOCAL_ENV_ID.databases")
  array_has_value "$database_id" && echo "$database_id" && return 0
  echo "\"$database_id\" is not a configured database."
  return 1
}

# Ensure a given environment ID is valid AND ACTIVE
#
# $1 - A environment ID, which is active, that is local, remote or other.
#
# @code
# ! id=$(validate_environment "$id") && echo "$id" && return 1
# echo "$id" && return 0
# @endcode
#
# Returns 0 and echos the ID if valid; otherwise echo error and return 1
function validate_environment() {
  local environment_id="$1"

  for id in "${ACTIVE_ENVIRONMENTS[@]}"; do
     [[ "$id" == "$environment_id" ]] && echo "$environment_id" && return 0
  done
  echo "\"$environment_id\" is not active.  If it has been added to config.yml, then set as \"local\", \"remote\" or add to \"other\" in config.local.yml."
  return 1
}

# All pass-through variables must be set prior to calling.
#
# $1 - the workflow ID.
#
# Returns 0 if .
function execute_workflow_processors() {
  local workflow="$1"
  local type="${2:-processors}"

  local processor
  local processor_path
  local processor_output
  local processor_result
  local key
  local php_query
  eval $(get_config_as -a processors "workflows.$workflow.$type")
  for basename in "${processors[@]}"; do
    processor_path="$CONFIG_DIR/processors/$basename"
    processor="$(path_make_relative "$processor_path" "$CLOUDY_BASEPATH")"

    if [[ "$(path_extension "$processor_path")" == "sh" ]]; then
      [[ ! -f "$processor_path" ]] && fail_because "Missing file processor: $processor" && return 1
      [[ "$JSON_RESPONSE" != true ]] && echo_task "$(path_make_relative "$processor_path" "$CONFIG_DIR")"
      processor_output=$(cd "$CLOUDY_BASEPATH"; source "$SOURCE_DIR/processor_support.sh"; . "$processor_path")
      processor_result=$?
    else
      php_query="autoload=$CONFIG_DIR/processors/&COMMAND=$COMMAND&LOCAL_ENV_ID=$LOCAL_ENV_ID&REMOTE_ENV_ID=$REMOTE_ENV_ID&DATABASE_ID=$DATABASE_ID&DATABASE_NAME=$DATABASE_NAME&FILES_GROUP_ID=$FILES_GROUP_ID&FILEPATH=$FILEPATH&SHORTPATH=$SHORTPATH&IS_WRITEABLE_ENVIRONMENT=$IS_WRITEABLE_ENVIRONMENT"
      local processor_class
      processor_class=$(call_php_class_method "\AKlump\LiveDevPorter\Helpers\ResolveClassShortname::__invoke($basename,'\AKlump\LiveDevPorter\Processors')")
      processor_result=$?
      if [[ $processor_result -ne 0 ]]; then
        processor_output="$processor_class"
      else
        [[ "$JSON_RESPONSE" != true ]] && echo_task "$(path_make_relative "$processor_path" "$CONFIG_DIR")"
        processor_output=$(cd "$CLOUDY_BASEPATH"; $CLOUDY_PHP "$ROOT/php/class_method_caller.php" "$processor_class" "$php_query")
        processor_result=$?
      fi
    fi

    if [[ $processor_result -eq 255 ]]; then
      [[ "$JSON_RESPONSE" != true ]] && clear_task
    elif [[ $processor_result -ne 0 ]]; then
      [[ "$JSON_RESPONSE" != true ]] && echo_task_failed
      [[ "$processor_output" ]] && fail_because "$processor_output"
      if [[ "$FILES_GROUP_ID" ]]; then
        fail_because "\"$processor\" has failed while processing: $SHORTPATH (in files group \"$FILES_GROUP_ID\")."
      else
        fail_because "\"$processor\" has failed while processing database: $DATABASE_ID."
      fi
      return 1
    else
      [[ "$JSON_RESPONSE" != true ]] && echo_task_completed
      [[ "$processor_output" ]] && succeed_because "$processor_output"
    fi
  done

  return 0
}

# Call a plugin function.
#
# NEVER DO $(call_plugin...) AS IT WILL SUPPRESS MESSAGES.
#
# $1 - The name of the plugin
# $2 - The function name without the plugin leader, so for a function
# called pantheon_on_fetch_db, you would pass 'fetch_db'.
# $... Additional arguments exclusively will be passed to the plugin function.
#
function call_plugin() {
  local plugin="$1"
  local plugin_hook="$2"
  local plugin_args=("${@:3}")

  local func_name
  func_name=$(_plugin_get_func_name "$plugin" "$plugin_hook")
  ! plugin_implements $plugin $plugin_hook && fail_because "Plugin \"$plugin\" does not define a function called $func_name()" && return 1
  write_log_debug "Calling plugin with: $func_name"
  $func_name "${plugin_args[@]}"
}

##
 # Calls the correct remote database plugin for a given call.
 #
 # @param string The plugin hook, e.g., pull_db
 ##
function call_remote_database_plugin() {
  local plugin_hook=$1
  local database_id="$2"
  local plugin_args=("${@:1}")

  local plugin
  local result

  [[ ! "$REMOTE_ENV_ID" ]] && fail_because "Empty value for \$REMOTE_ENV_ID" && return 1

  # This is the default handler for remote environments.  It may be replaced if
  # the remote environment is using the backups plugin...
  plugin="mysql"

  # ... check if the remote environment is using the filepath plugin for the
  # database, which means that a local copy of the dumpfile already exists.
  environment_uses_backups_plugin "$REMOTE_ENV_ID" && plugin="backups"

  call_plugin "$plugin" "${plugin_args[@]}"
}

##
 # Load a plugin that is not currently active.
 #
 # @param string The name of the plugin.
 #
 # @return 1 If the plugin cannot be found.
 ##
function load_plugin() {
  local plugin="$1"

  [ -f "$PLUGINS_DIR/$plugin/$plugin.sh" ] || return 1
  source "$PLUGINS_DIR/$plugin/$plugin.sh"
  write_log_debug "$plugin plugin loaded"
}

function _plugin_get_func_name() {
  local plugin="$1"
  local plugin_hook="$2"

  echo "${plugin}_on_${plugin_hook}"
}

# Test if a given plugin implements a hook.
#
# $1 - The plugin name.
# $2 - The hook base, e.g. 'pull_db'.  Will look for PLUGIN_on_pull_db().
#
# Returns 0 if .
function plugin_implements() {
  local plugin="$1"
  local plugin_hook="$2"

  load_plugin "$plugin" || return $?
  function_exists "$(_plugin_get_func_name "$plugin" "$plugin_hook")"
}

##
 # Check if an environment is using the backups plugin.
 #
 # @return 0 If it is, 1 otherwise
 ##
function environment_uses_backups_plugin() {
  local $environment_id

  load_plugin "backups"
  backups_get_database_filepath "$environment_id" "$database_id" &>/dev/null
  [[ "$?" -ne 1 ]] && return 0
  return 1
}

function implement_route_access() {
  command=$(get_command)

  local access

  eval $(get_config_as require_remote "commands.${command}.require_remote_env")
  eval $(get_config_as require_write "commands.${command}.require_write_access")
  eval $(get_config_as require_remote_write "commands.${command}.require_remote_write_access")

  # No special perms required.
  [[ "$require_write" != true ]] && [[ "$require_remote_write" != true ]] && [[ "$require_remote" != true ]] && return 0

  eval $(get_config_as write_access "environments.$LOCAL_ENV_ID.write_access")
  if [[ "$require_write" == true ]] && [[ "$write_access" != true ]]; then
    fail_because "write_access is false for the \"$LOCAL_ENV_ID\" environment."
    fail_because "set to true in the configuration, to allow this command."
  fi

  eval $(get_config_as remote_write_access "environments.$REMOTE_ENV_ID.write_access")
  if [[ "$require_remote_write" == true ]] && [[ "$remote_write_access" != true ]]; then
    fail_because "write_access is false for the \"$REMOTE_ENV_ID\" environment."
    fail_because "set to true in the configuration, to allow this command."
  fi

  eval $(get_config_as remote "remote")
  if [[ "$require_remote" == true ]] && [[ "$remote" == null ]]; then
    fail_because "This command requires a remote environment be configured."
  fi
  has_failed && exit_with_failure "\"$command\" not allowed in this environment."
  return 0
}

# Checks if you will need to connect using SSH to an environment
#
# $1 - An environment ID with which you wish to communicate.
#
# Returns 0 if you need ssh; 1 if not.
#
# @see get_ssh_auth()
function is_ssh_connection() {
  local environment_id="$1"

  auth=$(get_ssh_auth "$environment_id")
  [[ "$auth" != "" ]] && return 0
  return 1
}

# If an environment is on another server this will echo the ssh auth.
#
# @code
# auth=$(get_ssh_auth "$REMOTE_ENV_ID")
# @endcode
#
# $1 - An environment ID with which you wish to communicate.
#
function get_ssh_auth() {
  local environment_id="$1"

  eval $(get_config_as a "environments.$LOCAL_ENV_ID.ssh")
  eval $(get_config_as b "environments.$environment_id.ssh")
  if [[ "$b" ]] && [[ "$a" != "$b" ]]; then
    echo "${b}"
  fi
}

## Echo an absolute path to a given environment path.
 #
 # @param string The environment ID.
 # @param string Optional relative path and will be appended to the environment's base_path if provided.
 #
 # @echo The absolute path for the given environment, only if successful.
 # @return 0 if successful
 # @return 1 if failed.
##
function environment_path_resolve() {
  local environment_id="$1"
  local relative_path="$2"

  path_is_absolute "$relative_path" && fail_because "Second argument may only be a relative path or omitted." && return 1
  eval $(get_config_path_as "path" "environments.$environment_id.base_path")
  [[ ! "$path" ]] && fail_because "Missing config for: environments.$environment_id.base_path" && return 1

  [[ "$relative_path" ]] && p="$(path_make_absolute "$relative_path" "$path")" && path="$p"
  echo "$path"
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

# Connect to a remote environment by ID.
#
# $1 - The (remote) environment ID.
#
# Returns 0 if .
function remote_ssh() {
  # DO NOT ECHO ANYTHING IN THIS METHOD AS IT WILL SCREW UP THE JSON PARSING!
  local environment_id="$1"

  env_auth=$(get_ssh_auth "$environment_id")
  [[ "$env_auth" ]] || return 1
  write_log_debug "ssh -t -o BatchMode=yes "$env_auth" "${@:2}""
  if has_option "verbose"; then
    verbose=" -vvv"
  fi
  ssh$verbose -t -o BatchMode=yes "$env_auth" "${@:2}"
}

function echo_time_heading() {
  echo "$LIL $(time_local)"
}

function echo_red_path_if_nonexistent() {
  local path="$1"
  local display_path="$2"

  if [[ ! "$display_path" ]]; then
    display_path="$path"
  fi
  if [[ ! -e "$path" ]]; then
    echo_red "$display_path"
  else
    echo "$display_path"
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

# Sets an error message as a JSON object
#
# $1 - The error message
#
# Returns nothing.
function json_set_error() {
  local message="$1"

  message=${message//\"/\'}
  message=${message//\\n/ }
  message=${message%% }
  message=${message## }

  json_set "{\"error\":\"$message\"}"
}
