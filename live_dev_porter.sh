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

eval $(get_config_as 'REMOTE_ENV_ID' 'remote')
exit_with_failure_if_empty_config 'REMOTE_ENV_ID' 'remote'

# This is the localized environment name
eval $(get_config_as 'REMOTE_ENV' "environments.$REMOTE_ENV_ID.id")
exit_with_failure_if_empty_config 'REMOTE_ENV' "environments.$REMOTE_ENV_ID.id"

eval $(get_config_as 'LOCAL_ENV_ID' 'local')
exit_with_failure_if_empty_config 'LOCAL_ENV_ID' 'local'

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

eval $(get_config_as 'FETCH_PLUGIN' "environments.$REMOTE_ENV_ID.fetch.plugin")
eval $(get_config_as 'RESET_PLUGIN' "environments.$LOCAL_ENV_ID.reset.plugin")
EXPORT_PLUGIN="mysql"

# This is a local, non SCM file to overwrite the above hooks
if [ -f "$CONFIG_DIR/hooks.local.sh" ]; then
  source "$CONFIG_DIR/hooks.local.sh"
fi

# Handle other commands.
command=$(get_command)
case $command in

    "export")
      eval $(get_config_as "name" "environments.dev.database.name")
      echo_heading "Export $LOCAL_ENV database \"$name\""
      eval $(get_config_path_as 'LOCAL_EXPORT_DIR' 'environments.dev.export.path')
      exit_with_failure_if_empty_config 'LOCAL_EXPORT_DIR' 'environments.dev.export.path'
      EXPORT_DB_PATH="$LOCAL_EXPORT_DIR/$LOCAL_ENV/db"
      if ! mkdir -p "$EXPORT_DB_PATH"; then
        fail_because "Could not create export directory at $EXPORT_DB_PATH"
      else
        source "$PLUGINS_DIR/$EXPORT_PLUGIN/plugin.sh"
        ${EXPORT_PLUGIN}_export_db || fail
      fi
      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "init")
      source "$SOURCE_DIR/init.sh"
      source "$PLUGINS_DIR/$EXPORT_PLUGIN/plugin.sh"
      ${EXPORT_PLUGIN}_init || fail
      source "$PLUGINS_DIR/$FETCH_PLUGIN/plugin.sh"
      ${FETCH_PLUGIN}_init || fail
      if [[ "$FETCH_PLUGIN" != "$RESET_PLUGIN" ]]; then
        source "$PLUGINS_DIR/$RESET_PLUGIN/plugin.sh"
        ${RESET_PLUGIN}_init || fail
      fi
      has_failed && exit_with_failure
      exit_with_success
    ;;

    "fetch")
      source "$PLUGINS_DIR/$FETCH_PLUGIN/plugin.sh"

      if [[ "$do_database" == true ]]; then
        (hook_before_fetch_db)
        ${FETCH_PLUGIN}_authenticate || fail
        ${FETCH_PLUGIN}_clear_cache
        echo "Fetching the $REMOTE_ENV database"

        # todo insert the last fetch time here.
        echo "Last time this took N minutes, so please be patient"

        delete_pulled_db
        ${FETCH_PLUGIN}_fetch_db || fail
        store_timestamp "$PULL_DB_PATH"
        (hook_after_fetch_db)
      fi
      if [[ "$do_files" == true ]]; then
        (hook_before_fetch_files)
        echo "Fetching the $REMOTE_ENV files, please wait..."
        ${FETCH_PLUGIN}_fetch_files || exit 1
        store_timestamp "$PULL_FILES_PATH"
        (hook_after_fetch_files)
      fi
      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "reset")
      source "$PLUGINS_DIR/$RESET_PLUGIN/plugin.sh"

      # import the database.
      if [[ "$do_database" == true ]]; then
        (hook_before_reset_db)
        basename=$(get_pulled_db_basename)
        if [[ ! "$basename" ]]; then
          echo "You must pull -d first."
          exit 1
        fi
        echo "Resetting local database, please wait..."
        ${RESET_PLUGIN}_reset_db || fail
        (hook_after_reset_db)
      fi

      if [[ "$do_files" == true ]]; then
        (hook_before_reset_files)
        echo "Resetting local files to match $REMOTE_ENV"
        ${RESET_PLUGIN}_reset_files || fail
        (hook_after_reset_files)
      fi

      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "pull")
      source "$PLUGINS_DIR/$FETCH_PLUGIN/plugin.sh"
      if [[ "$FETCH_PLUGIN" != "$RESET_PLUGIN" ]]; then
        source "$PLUGINS_DIR/$RESET_PLUGIN/plugin.sh"
      fi

      if [[ "$do_database" == true ]]; then
        ${FETCH_PLUGIN}_authenticate || exit 1
        ${FETCH_PLUGIN}_clear_cache
        echo "Fetching the remote database, please wait..."
        delete_pulled_db
        ${FETCH_PLUGIN}_fetch_db
        echo "Resetting the local database to match remote."
        ${RESET_PLUGIN}_reset_db
      fi

      # rsync the files
      if [[ "$do_files" == true ]]; then
        echo "Fetching the $REMOTE_ENV files, please wait..."
        ${FETCH_PLUGIN}_fetch_files || exit 1
        ${RESET_PLUGIN}_reset_files
      fi

      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "info")
      source "$SOURCE_DIR/info.sh"

      source "$PLUGINS_DIR/$FETCH_PLUGIN/plugin.sh"
      ${FETCH_PLUGIN}_info

      if [[ "$FETCH_PLUGIN" != "$RESET_PLUGIN" ]]; then
        source "$PLUGINS_DIR/$RESET_PLUGIN/plugin.sh"
        ${RESET_PLUGIN}_info
      fi
      has_failed && exit_with_failure
      exit_with_success
    ;;
esac

throw "Unhandled command \"$command\"."
