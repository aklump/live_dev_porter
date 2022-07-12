#!/usr/bin/env bash
#
# @file
# Simplifies the management and transfer of assets between website environments.
#

# Define the configuration file relative to this script.
CONFIG="live_dev_porter.core.yml";

# Uncomment this line to enable file logging.
#LOGFILE="live_dev_porter.core.log"

# Call a php class method
#
# $1 - The PHP class (not-static) method, e.g. "\SchemaBuilder::build".
# $2 - An encoded query string.  This will be passed to the class constructor
# as the first argument.  Note: The class constructor will receive cloudy config
# as the second argument; see caller.php for more info.
#
# Returns 0 if .
function call_php_class_method() {
  local callback="$1"
  local query_string="$2"

  export CLOUDY_CONFIG_JSON
  message="$($CLOUDY_PHP "$ROOT/php/class_method_caller.php" "$callback" "$query_string")"
  status=$?
  if [[ $status -ne 0 ]]; then
    fail_because "$message"
    exit_with_failure "$callback() failed."
  elif [[ "$message" ]]; then
    succeed_because "$message"
  fi
}

function on_pre_config() {
  if [[ "$(get_command)" == "init" ]]; then
    handle_init || exit_with_failure "${CLOUDY_FAILED:-Initialization failed.}"
  fi

  SOURCE_DIR="$ROOT/scripts"
  TEMP_DIR=$(tempdir $CLOUDY_NAME)
  PLUGINS_DIR="$ROOT/plugins"
  ALL_PLUGINS=()
  for i in $(cd $PLUGINS_DIR && find . -maxdepth 1 -type d); do
     [[ "$i" != '.' ]] && ALL_PLUGINS=("${ALL_PLUGINS[@]}" "$(basename "$i")")
  done
  source "$SOURCE_DIR/functions.sh"
  source "$SOURCE_DIR/database.sh"
}

function on_compile_config() {
  for plugin in "${ALL_PLUGINS[@]}"; do
    plugin_implements $plugin on_compile_config && call_plugin $plugin on_compile_config
  done
}

function on_clear_cache() {
  call_php_class_method "\AKlump\LiveDevPorter\Config\SchemaBuilder::destroy" "CACHE_DIR=$CONFIG_DIR/.cache"
  for plugin in "${ACTIVE_PLUGINS[@]}"; do
    plugin_implements "$plugin" on_clear_cache && call_plugin "$plugin" on_clear_cache
  done
}

function on_boot() {
  CONFIG_DIR="$APP_ROOT/.live_dev_porter"
  CACHE_DIR="$CONFIG_DIR/.cache"

  # Do not write code below this line.
  [[ "$(get_command)" == "tests" ]] || return 0
  source "$CLOUDY_ROOT/inc/cloudy.testing.sh"
  echo_heading "Testing core"
  do_tests_in "$SOURCE_DIR/live_dev_porter.tests.sh"
  for plugin in "${ALL_PLUGINS[@]}"; do
    local testfile="$PLUGINS_DIR/$plugin/$plugin.tests.sh"
    if [ -f "$testfile" ]; then
      echo_heading "Testing plugin: $(string_ucfirst $plugin)"
      source "$PLUGINS_DIR/$plugin/$plugin.sh"
      do_tests_in --continue "$testfile"
    fi
  done
  echo
  exit_with_test_results
}

# Begin Cloudy Bootstrap
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";source "$r/cloudy/cloudy.sh";[[ "$ROOT" != "$r" ]] && echo "$(tput setaf 7)$(tput setab 1)Bootstrap failure, cannot load cloudy.sh$
}
}(tput sgr0)" && exit 1
# End Cloudy Bootstrap

# Input validation.
validate_input || exit_with_failure "Input validation failed."

COMMAND=$(get_command)
case $COMMAND in
    "init")
      source "$SOURCE_DIR/init.sh"
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        plugin_implements $plugin init && call_plugin $plugin init
      done
      has_failed && exit_with_failure
      exit_with_success "Initialization complete."
      ;;

    "config")
      if [[ ! "$EDITOR" ]]; then
        exit_with_failure "You must set environment variable \$EDITOR with a command first, e.g. in ~/.bash_profile, export EDITOR=nano"
      fi
      config_file="$CONFIG_DIR/config.yml"
      if has_option 'local'; then
        config_file="$CONFIG_DIR/config.local.yml"
      fi
      $EDITOR $config_file && exit_with_cache_clear
      ;;

esac

eval $(get_config_as LOCAL_ENV_ID 'environment')
exit_with_failure_if_empty_config 'LOCAL_ENV_ID' 'environment'
eval $(get_config_as REMOTE_ENV_ID 'remote_environment')

eval $(get_config_keys_as 'keys' "environments")
for key in "${keys[@]}"; do
  eval $(get_config_as "id" "environments.${key}.id")
  if [[ "$id" == "$LOCAL_ENV_ID" ]]; then
    LOCAL_ENV_KEY=$key

    # Assign the default local database.
    eval $(get_config_keys_as "ids" "environments.$LOCAL_ENV_KEY.databases")
    LOCAL_DATABASE_ID=${ids[0]}

  # Configure remote variables if we have that environment.
  elif [[ "$REMOTE_ENV_ID" ]] && [[ "$id" == "$REMOTE_ENV_ID" ]]; then
    REMOTE_ENV_KEY=$key
    eval $(get_config_as REMOTE_ENV_AUTH "environments.${key}.ssh")
    exit_with_failure_if_empty_config REMOTE_ENV_AUTH "environments.${key}.ssh"

    eval $(get_config_keys_as "ids" "environments.$REMOTE_ENV_KEY.databases")
    REMOTE_DATABASE_ID=${ids[0]}
  fi
done

eval $(get_config_keys_as -a 'keys' "databases")
DATABASE_IDS=()
for key in "${keys[@]}"; do
  eval $(get_config_as -a 'id' "databases.${key}.id")
  DATABASE_IDS=("${DATABASE_IDS[@]}" "$id")
done

eval $(get_config_keys_as -a 'keys' "file_groups")
FILE_GROUP_IDS=()
for key in "${keys[@]}"; do
  eval $(get_config_as -a 'id' "file_groups.${key}.id")
  FILE_GROUP_IDS=("${FILE_GROUP_IDS[@]}" "$id")
done

# Bootstrap the plugin configuration.
source "$SOURCE_DIR/plugins.sh"
for plugin in "${ACTIVE_PLUGINS[@]}"; do
  plugin_implements $plugin on_boot && call_plugin $plugin on_boot
done

# Define all hooks, which can be overwritten by the plugin or config/hooks.local.
source "$SOURCE_DIR/hooks.sh"

# This is a local, non SCM file to overwrite the above hooks
if [ -f "$CONFIG_DIR/hooks.local.sh" ]; then
  source "$CONFIG_DIR/hooks.local.sh"
fi


# Initialize local stash directory.
#pull_to_path="$LOCAL_FETCH_DIR/$REMOTE_ENV_ID/"
#mkdir -p "$pull_to_path/db" || exit 1
#mkdir -p "$pull_to_path/files" || exit 1
#FETCH_DB_PATH=$(cd "$pull_to_path/db" && pwd)
#FETCH_FILES_PATH=$(cd "$pull_to_path/files" && pwd)

# Determine if we are going to operate on database, files, or both.
if has_option d && has_option f; then
  do_database=true
  do_files=true
elif has_option d; then
  do_database=true
  do_files=false
elif has_option f; then
  do_database=false
  do_files=true
else
  do_database=true
  do_files=true
fi


if [[ "$CLOUDY_CONFIG_HAS_CHANGED" == true ]] && [[ "$COMMAND" != "clear-cache" ]]; then
  call_php_class_method "\AKlump\LiveDevPorter\Config\RsyncHelper::createFiles" "CACHE_DIR=$CONFIG_DIR/.cache"
  call_php_class_method "\AKlump\LiveDevPorter\Config\SchemaBuilder::build"  "CACHE_DIR=$CONFIG_DIR/.cache"
  call_php_class_method "\AKlump\LiveDevPorter\Config\Validator::validate" "CACHE_DIR=$CONFIG_DIR/.cache"

  for plugin in "${ACTIVE_PLUGINS[@]}"; do
    plugin_implements "$plugin" rebuild_config && call_plugin "$plugin" rebuild_config
  done
fi
# keep this after has changed or the help route will not build
implement_cloudy_basic
implement_route_access

# Handle other commands.
case $COMMAND in

    "configtest")
      echo_title "CONFIGURATION TESTS"
      implement_configtest
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        if plugin_implements $plugin configtest; then
          echo_heading "Plugin: $(string_ucfirst "$plugin")"
          output=$(call_plugin $plugin configtest)
          [[ "$output" ]] && echo "$output" && echo
        fi
      done
      has_failed && fail_because "Try clearing caches." && exit_with_failure "Tests failed."
      exit_with_success "All tests passed."
      ;;

    "remote")
      call_plugin $PLUGIN_REMOTE_SSH_SHELL remote_shell || fail
      has_failed && exit_with_failure
      exit_with_success_elapsed
      ;;

    "db")
      database_id=$(get_command_arg 0 "$LOCAL_DATABASE_ID")
      eval $(get_config_as plugin 'plugin_assignments.local.databases')
      echo_title "$LOCAL_ENV_ID database \"$database_id\""
      call_plugin $plugin db_shell "$database_id" || fail
      has_failed && exit_with_failure
      exit_with_success_elapsed
      ;;

    "import")
      eval $(get_config_as "name" "environments.dev.database.name")
      echo_title "Replace $LOCAL_ENV_ID database \"$name\" with import (via $PLUGIN_IMPORT_TO_LOCAL_DB)"
      eval $(get_config_path_as 'LOCAL_EXPORT_DIR' 'environments.dev.export.path')
      exit_with_failure_if_empty_config 'LOCAL_EXPORT_DIR' 'environments.dev.export.path'
      EXPORT_DB_PATH="$LOCAL_EXPORT_DIR/$LOCAL_ENV_ID/db"
      if [ ! -d $EXPORT_DB_PATH ]; then
        fail_because "Missing directory $EXPORT_DB_PATH"
      else
        dumpfiles=()
        for i in $(cd "$EXPORT_DB_PATH" && find . -maxdepth 1 -type f -name '*.sql*'); do
           [[ "$i" != '.' ]] && dumpfiles=("${dumpfiles[@]}" "$(basename "$i")")
        done
        echo
        PS3="Which dumpfile? (CTRL-C to cancel) "
        select dumpfile in ${dumpfiles[@]}; do
          echo_heading "Preparing..."
          ldp_db_drop_tables
          echo_heading "Importing..."
          call_plugin $PLUGIN_IMPORT_TO_LOCAL_DB import_db "$EXPORT_DB_PATH/$dumpfile" || fail
          message="import $dumpfile"
          if has_failed; then
            echo_fail "$message"
          else
            echo_pass "$message"
          fi
          break
        done
      fi
      has_failed && exit_with_failure "The import failed"
      exit_with_success_elapsed "The import was successful"
      ;;

    "export")
      id=$(get_option 'id' $LOCAL_DATABASE_ID)
      echo_title "Export $LOCAL_ENV_ID database \"$id\" (via $PLUGIN_EXPORT_LOCAL_DB)"
#      call_plugin $PLUGIN_EXPORT_LOCAL_DB export_db "$id" "$(get_command_arg 0)" || fail
      has_failed && exit_with_failure "Failed to export database"
      has_option all && succeed_because "All tables and data exported."

      workflow=$(get_option 'workflow')
      if [[ ! "$workflow" ]]; then
        eval $(get_config_as "workflow" "environments.$LOCAL_ENV_KEY.command_workflows.$COMMAND")
      fi
      if [[ "$workflow" ]]; then
        ENVIRONMENT_ID="$LOCAL_ENV_ID"
        DATABASE_ID="$id"
        execute_workflow_processors "$workflow" || exit_with_failure
      fi

#      store_timestamp "$EXPORT_DB_PATH"
      exit_with_success_elapsed "Database exported"
    ;;

    "pull")
      echo_title "Pulling from remote"
      [[ ${#DATABASE_IDS[@]} -eq 0 ]] && has_db=false || has_db=true
      [[ ${#FILE_GROUP_IDS[@]} -eq 0 ]] && has_files=false || has_files=true

      if [[ "$has_db" == false ]] && [[ "$has_files" == false ]]; then
        fail_because "Nothing to pull; neither \"databases\" nor \"files_group\" have been configured."
      fi

      workflow=$(get_option 'processor')
      if [[ ! "$workflow" ]]; then
        eval $(get_config_as "workflow" "environments.$LOCAL_ENV_KEY.processors.export")
      fi

      if ! has_failed && [[ "$do_database" == true ]]; then
        if [[ "$has_db" == false ]]; then
          if has_option d; then
            fail_because "Use of -d is out of context; \"databases\" has not been configured."
          elif has_option v; then
            succeed_because "No databases defined; skipping database component."
          fi
        else
          call_plugin $PLUGIN_PULL_DB authenticate || fail
          ! has_failed && call_plugin $PLUGIN_PULL_DB pull_databases || fail
        fi
      fi

      if ! has_failed && [[ "$do_files" == true ]]; then
        if [[ "$has_files" == false ]]; then
          if has_option f; then
            fail_because "Use of -f is out of context; \"file_groups\" has not been configured."
          elif has_option v; then
            succeed_because "No file_groups defined; skipping files component."
          fi
        else
          call_plugin $PLUGIN_PULL_FILES pull_files || fail
        fi
      fi
      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "info")
      source "$SOURCE_DIR/info.sh"
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        plugin_implements $plugin info && call_plugin $plugin info
      done
      has_failed && exit_with_failure
      exit_with_success "Use 'help' to see all commands."
    ;;
esac

throw "Unhandled command \"$COMMAND\"."
