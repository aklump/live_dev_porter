#!/usr/bin/env bash

#
# @file
# Simplifies the management and transfer of assets between website environments.
#

# Define the configuration file relative to this script.
CONFIG="live_dev_porter.core.yml";

# Uncomment this line to enable file logging.
#LOGFILE="live_dev_porter.core.log"

# TODO: Event handlers and other functions go here or register one or more includes in "additional_bootstrap".
function on_pre_config() {
  if [[ "$(get_command)" == "init" ]]; then
    handle_init || exit_with_failure "${CLOUDY_FAILED:-Initialization failed.}"
  fi
}

# Begin Cloudy Bootstrap
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";source "$r/../../cloudy/cloudy/cloudy.sh";[[ "$ROOT" != "$r" ]] && echo "$(tput setaf 7)$(tput setab 1)Bootstrap failure, cannot load cloudy.sh$(tput sgr0)" && exit 1
# End Cloudy Bootstrap

#@todo remove
ROOT_DIR="$ROOT"

SOURCE_DIR="$ROOT/src"
source "$SOURCE_DIR/functions.sh"

CONFIG_DIR="$APP_ROOT/.live_dev_porter"
PLUGINS_DIR="$ROOT/plugins"

TEMP_DIR=$(tempdir $CLOUDY_NAME)

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

implement_cloudy_basic

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

# Define all hooks, which can be overwritten by the plugin or config/hooks.local.
source "$SOURCE_DIR/hooks.sh"

# Bootstrap the plugin configuration.
source "$SOURCE_DIR/plugins.sh"

# This is a local, non SCM file to overwrite the above hooks
if [ -f "$CONFIG_DIR/hooks.local.sh" ]; then
  source "$CONFIG_DIR/hooks.local.sh"
fi

# Handle other commands.
command=$(get_command)
case $command in

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

    "init")
      source "$SOURCE_DIR/init.sh"
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        call_plugin $plugin init
      done
      has_failed && exit_with_failure
      exit_with_success
    ;;

    "export")
      eval $(get_config_as "name" "environments.dev.database.name")
      echo_heading "Export $LOCAL_ENV database \"$name\""
      eval $(get_config_path_as 'LOCAL_EXPORT_DIR' 'environments.dev.export.path')
      exit_with_failure_if_empty_config 'LOCAL_EXPORT_DIR' 'environments.dev.export.path'
      EXPORT_DB_PATH="$LOCAL_EXPORT_DIR/$LOCAL_ENV/db"
      if ! mkdir -p "$EXPORT_DB_PATH"; then
        fail_because "Could not create export directory at $EXPORT_DB_PATH"
      else
        call_plugin $PLUGIN_EXPORT_DB export_db || fail
      fi
      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "fetch")

      if [[ "$do_database" == true ]]; then
        source "$PLUGINS_DIR/$PLUGIN_FETCH_DB/${PLUGIN_FETCH_DB}.sh"
        echo_heading "Fetching the $REMOTE_ENV database"
        (hook_before_fetch_db)

        call_plugin $PLUGIN_FETCH_DB authenticate || exit_with_failure
        call_plugin $PLUGIN_FETCH_DB clear_cache || exit_with_failure

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

        dumpfile=$(get_path_to_fetched_db)
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
          call_plugin $PLUGIN_FETCH_DB clear_cache
          echo_heading "Fetching the remote database, please wait..."
          delete_last_fetched_db
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
      exit_with_success
    ;;
esac

throw "Unhandled command \"$command\"."
