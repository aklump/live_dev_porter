#!/usr/bin/env bash

#
# @file
# Simplifies the management and transfer of assets between website environments.
#

# Define the configuration file relative to this script.
CONFIG="live_dev_porter.core.yml";

# Uncomment this line to enable file logging.
#LOGFILE="live_dev_porter.core.log"

function on_pre_config() {
  if [[ "$(get_command)" == "init" ]]; then
    handle_init || exit_with_failure "${CLOUDY_FAILED:-Initialization failed.}"
  fi

  SOURCE_DIR="$ROOT/src"
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
    call_plugin $plugin on_compile_config
  done
}

function on_clear_cache() {
  # Delete the generated DB credentials file.
  local path_to_db_creds=$(ldp_get_db_creds_path)
  if [ -f "$path_to_db_creds" ]; then
    rm -f "$path_to_db_creds" || return 1
  fi
  succeed_because $(echo_green "$(path_unresolve "$CACHE_DIR" "$path_to_db_creds")")

  for plugin in "${ACTIVE_PLUGINS[@]}"; do
    call_plugin $plugin on_clear_cache
  done
}

# Begin Cloudy Bootstrap
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";source "$r/../../cloudy/cloudy/cloudy.sh";[[ "$ROOT" != "$r" ]] && echo "$(tput setaf 7)$(tput setab 1)Bootstrap failure, cannot load cloudy.sh$(tput sgr0)" && exit 1
# End Cloudy Bootstrap

CONFIG_DIR="$APP_ROOT/.live_dev_porter"

# Bootstrap the plugin configuration.
source "$SOURCE_DIR/plugins.sh"

# Define all hooks, which can be overwritten by the plugin or config/hooks.local.
source "$SOURCE_DIR/hooks.sh"

# This is a local, non SCM file to overwrite the above hooks
if [ -f "$CONFIG_DIR/hooks.local.sh" ]; then
  source "$CONFIG_DIR/hooks.local.sh"
fi

eval $(get_config_path_as 'LOCAL_FETCH_DIR' 'environments.dev.fetch.path')
exit_with_failure_if_empty_config 'LOCAL_FETCH_DIR' 'environments.dev.fetch.path'

eval $(get_config_as 'REMOTE_ENV_ID' 'remote_environment_is')
if [[ "$REMOTE_ENV_ID" ]]; then
  eval $(get_config_as 'REMOTE_ENV' "environments.$REMOTE_ENV_ID.id")
  exit_with_failure_if_empty_config 'REMOTE_ENV' "environments.$REMOTE_ENV_ID.id"
fi

eval $(get_config_as 'LOCAL_ENV_ID' 'local_environment_is')
exit_with_failure_if_empty_config 'LOCAL_ENV_ID' 'local_environment_is'

# This is the localized environment id
eval $(get_config_as 'LOCAL_ENV' "environments.$LOCAL_ENV_ID.id")
exit_with_failure_if_empty_config 'LOCAL_ENV' "environments.$REMOTE_ENV_ID.id"

# Input validation.
validate_input || exit_with_failure "Input validation failed."

# Initialize local stash directory.
pull_to_path="$LOCAL_FETCH_DIR/$REMOTE_ENV/"
mkdir -p "$pull_to_path/db" || exit 1
mkdir -p "$pull_to_path/files" || exit 1
PULL_DB_PATH=$(cd "$pull_to_path/db" && pwd)
PULL_FILES_PATH=$(cd "$pull_to_path/files" && pwd)

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

implement_cloudy_basic

# Handle other commands.
command=$(get_command)
case $command in

    "configtest")
      echo_title "CONFIGURATION TESTS"
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        plugin_implements $plugin test && echo_heading $(string_ucfirst "$plugin")
        call_plugin $plugin test
      done
      has_failed && exit_with_failure "Tests failed."
      exit_with_success "All tests passed."
      ;;

    "init")
      source "$SOURCE_DIR/init.sh"
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        call_plugin $plugin init
      done
      has_failed && exit_with_failure
      exit_with_success "Initialization complete."
      ;;

    "db")
      call_plugin $PLUGIN_DB_SHELL db_shell || fail
      has_failed && exit_with_failure
      exit_with_success_elapsed
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

    "import")
      eval $(get_config_as "name" "environments.dev.database.name")
      echo_heading "Replace $LOCAL_ENV database \"$name\" with import (via $PLUGIN_IMPORT_DB)"
      eval $(get_config_path_as 'LOCAL_EXPORT_DIR' 'environments.dev.export.path')
      exit_with_failure_if_empty_config 'LOCAL_EXPORT_DIR' 'environments.dev.export.path'
      EXPORT_DB_PATH="$LOCAL_EXPORT_DIR/$LOCAL_ENV/db"
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
          call_plugin $PLUGIN_IMPORT_DB import_db "$EXPORT_DB_PATH/$dumpfile" || fail
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
      eval $(get_config_as "name" "environments.dev.database.name")
      echo_heading "Export $LOCAL_ENV database \"$name\" (via $PLUGIN_EXPORT_DB)"
      eval $(get_config_path_as 'LOCAL_EXPORT_DIR' 'environments.dev.export.path')
      exit_with_failure_if_empty_config 'LOCAL_EXPORT_DIR' 'environments.dev.export.path'
      EXPORT_DB_PATH="$LOCAL_EXPORT_DIR/$LOCAL_ENV/db"
      if ! mkdir -p "$EXPORT_DB_PATH"; then
        fail_because "Could not create export directory at $EXPORT_DB_PATH"
      else
        call_plugin $PLUGIN_EXPORT_DB export_db || fail
      fi
      has_failed && exit_with_failure "Failed to export database"
      has_option all && succeed_because "All tables and data exported."
      store_timestamp "$EXPORT_DB_PATH"
      exit_with_success_elapsed "Database exported"
    ;;

    "fetch")
      if [[ "$do_database" == true ]]; then
        source "$PLUGINS_DIR/$PLUGIN_FETCH_DB/${PLUGIN_FETCH_DB}.sh"
        echo_heading "Fetching the $REMOTE_ENV database"
        (hook_before_fetch_db)

        call_plugin $PLUGIN_FETCH_DB authenticate || exit_with_failure
        call_plugin $PLUGIN_FETCH_DB remote_clear_cach || exit_with_failure

        # todo insert the last fetch time here.
        echo "Last time this took N minutes, so please be patient"
        call_plugin $PLUGIN_FETCH_DB fetch_db || fail
        ! has_failed && store_timestamp "$PULL_DB_PATH"
        (hook_after_fetch_db)
      fi

      if [[ "$do_files" == true ]]; then
        echo_heading "Fetching the $REMOTE_ENV files, please wait..."
        (hook_before_fetch_files)
        call_plugin $PLUGIN_FETCH_FILES fetch_files || fail
        ! has_failed && store_timestamp "$PULL_FILES_PATH"
        (hook_after_fetch_files)
      fi
      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "reset")
      if [[ "$do_database" == true ]]; then
        echo_heading "Resetting local database, please wait..."
        (hook_before_reset_db)

        dumpfile=$(ldp_get_fetched_db_path)
        if [[ ! "$dumpfile" ]]; then
          fail_because "Missing database file (did you pull -d?)"
        fi
        if [ ! -f "$dumpfile" ]; then
          fail_because "Dumpfile does not exist \"$dumpfile\"."
        fi
        has_failed && exit_with_failure
        call_plugin $PLUGIN_RESET_DB reset_db "$dumpfile" || fail
        (hook_after_reset_db)
      fi

      if [[ "$do_files" == true ]]; then
        echo_heading "Resetting local files to match $REMOTE_ENV"
        (hook_before_reset_files)
        call_plugin $PLUGIN_RESET_FILES reset_files || fail
        (hook_after_reset_files)
      fi

      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "pull")
      if [[ "$do_database" == true ]]; then
        call_plugin $PLUGIN_FETCH_DB authenticate || fail
        if ! has_failed; then
          call_plugin $PLUGIN_FETCH_DB remote_clear_cach
          echo_heading "Fetching the remote database, please wait..."
          ldp_delete_fetched_db
          call_plugin $PLUGIN_FETCH_DB fetch_db || fail
        fi
        if ! has_failed; then
          echo_heading "Resetting the local database to match remote."
          call_plugin $PLUGIN_RESET_DB reset_db
        fi
      fi

      if [[ "$do_files" == true ]]; then
        echo_heading "Fetching the $REMOTE_ENV files, please wait..."
        call_plugin $PLUGIN_FETCH_FILES fetch_files || fail
        if ! has_failed; then
          echo_heading "Resetting the local files to match remote."
          call_plugin $PLUGIN_RESET_FILES reset_files
        fi
      fi
      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "info")
      source "$SOURCE_DIR/info.sh"
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        call_plugin $plugin info
      done
      has_failed && exit_with_failure
      exit_with_success "Use 'help' to see all commands."
    ;;
esac

throw "Unhandled command \"$command\"."
