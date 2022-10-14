#!/usr/bin/env bash
#
# @file
# Simplifies the management and transfer of assets between website environments.
#

# Define the configuration file relative to this script.
CONFIG="live_dev_porter.core.yml";

# Uncomment this line to enable file logging.
#LOGFILE="live_dev_porter.core.log"

# Call a php class method as set success/failure status and messaging.
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
  message="$($CLOUDY_PHP "$ROOT/php/class_method_caller.php" "$callback" "$query_string" "${@:3}")"
  status=$?
  if [[ $status -ne 0 ]]; then
    fail_because "$message"
    exit_with_failure "$callback() failed."
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
  local query_string="$2"

  export CLOUDY_CONFIG_JSON
  $CLOUDY_PHP "$ROOT/php/class_method_caller.php" "$callback" "$query_string" "${@:3}"
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
    plugin_implements $plugin on_compile_config && call_plugin $plugin compile_config
  done
}

function on_clear_cache() {
  call_php_class_method "\AKlump\LiveDevPorter\Config\SchemaBuilder::destroy" "CACHE_DIR=$CONFIG_DIR/.cache"

  # We have to do all plugins because a plugin may have changed, and if we only
  # did active ones, there inactive plugin will not know to clean up it's
  # generated files, e.g., lando.
  for plugin in "${ALL_PLUGINS[@]}"; do
    plugin_implements "$plugin" clear_cache && call_plugin "$plugin" clear_cache
  done
}

function on_boot() {
  CONFIG_DIR="$APP_ROOT/.live_dev_porter"
  CACHE_DIR="$CONFIG_DIR/.cache"
  [[ -d "$CACHE_DIR" ]] || mkdir -p "$CACHE_DIR"

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
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";source "$r/cloudy/cloudy.sh";[[ "$ROOT" != "$r" ]] && echo "$(tput setaf 7)$(tput setab 1)Bootstrap failure, cannot load cloudy.sh$(tput sgr0)" && exit 1
# End Cloudy Bootstrap

# Input validation.
validate_input || exit_with_failure "Input validation failed."

COMMAND=$(get_command)
case $COMMAND in
    "config-migrate")
      echo_title "Migrate from Loft Deploy"
      path_to_loft_deploy=$(get_command_arg 0 "$APP_ROOT/.loft_deploy")
      message="$($CLOUDY_PHP "$ROOT/php/migrate.php" "$path_to_loft_deploy")" || fail
      has_failed && fail_because "$message" && exit_with_failure "Migration failed."
      succeed_because "$message"
      exit_with_success "Migration complete"
      ;;

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

eval $(get_config_as LOCAL_ENV_ID 'local')
exit_with_failure_if_empty_config 'LOCAL_ENV_ID' 'local'

# We will scream if the local base path does not exist, this is because it's
# possible the config is incorrect and we should not allow commands below here
# to be executed in such state.
eval $(get_config_as local_base_path "environments.$LOCAL_ENV_ID.base_path")
if [[ ! -e "$local_base_path" ]]; then
  echo_scream "Configuration \"local: test\" doesn't look right"
  fail_because "Are you sure that \"$LOCAL_ENV_ID\" is the correct environment ID for local?"
  fail_because "If it is, do you need to simply create it's base_path: $local_base_path?"
  fail_because "Otherwise, you will need to configure local to other than \"$LOCAL_ENV_ID\" or correct \"$LOCAL_ENV_ID.base_path\"."
  exit_with_failure_if_config_is_not_path local_base_path "environments.$LOCAL_ENV_ID.base_path"
fi

ACTIVE_ENVIRONMENTS=("$LOCAL_ENV_ID")

eval $(get_config_as REMOTE_ENV_ID 'remote')
if [[ "$REMOTE_ENV_ID" ]] && [[ "$REMOTE_ENV_ID" != null ]]; then
  ACTIVE_ENVIRONMENTS=("${ACTIVE_ENVIRONMENTS[@]}" "$REMOTE_ENV_ID")
fi

eval $(get_config_as -a array_sort__array "other")
if [[ ${#array_sort__array} -gt 0 ]]; then
  array_sort
  ACTIVE_ENVIRONMENTS=("${ACTIVE_ENVIRONMENTS[@]}" "${array_sort__array[@]}")
fi

# Alter the remote environment via CLI when appropriate.
if [[ 'pull' == $COMMAND ]] || [[ 'remote' == $COMMAND ]]; then
  REMOTE_ENV_ID=$(get_command_arg 0 "$REMOTE_ENV_ID")
  ! REMOTE_ENV_ID=$(validate_environment "$REMOTE_ENV_ID") && fail_because "$REMOTE_ENV_ID" && exit_with_failure
fi

for id in "${ACTIVE_ENVIRONMENTS[@]}"; do
  if [[ "$id" == "$LOCAL_ENV_ID" ]]; then

    eval $(get_config_as "write_access" "environments.$LOCAL_ENV_ID.write_access" false)
    IS_WRITEABLE_ENVIRONMENT=false
    [[ "$write_access" == true ]] && IS_WRITEABLE_ENVIRONMENT=true

    # Assign the default local database.
    eval $(get_config_keys_as "LOCAL_DATABASE_IDS" "environments.$LOCAL_ENV_ID.databases")
    LOCAL_DATABASE_ID=${LOCAL_DATABASE_IDS[0]}

  # Configure remote variables if we have that environment.
  elif [[ "$REMOTE_ENV_ID" != null ]] && [[ "$id" == "$REMOTE_ENV_ID" ]]; then
    REMOTE_ENV_AUTH=$(get_ssh_auth "$id")
    [[ "$REMOTE_ENV_AUTH" ]] && REMOTE_ENV_AUTH="$REMOTE_ENV_AUTH:"

    eval $(get_config_keys_as "REMOTE_DATABASE_IDS" "environments.$REMOTE_ENV_ID.databases")
    REMOTE_DATABASE_ID=${REMOTE_DATABASE_IDS[0]}
  fi
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

[[ "$(get_option format)" == "json" ]] && JSON_RESPONSE=true

# Uncomment this to add additional developer commands.
#source "$SOURCE_DIR/developer_commands.sh"

# Handle other commands.
case $COMMAND in
    "config-test")
      echo_title "Test Configuration"
      implement_configtest
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        if plugin_implements $plugin configtest; then
          tput sc
          echo
          echo_heading "Plugin: $(string_ucfirst "$plugin")"
          call_plugin $plugin configtest
          if [[ $? -eq 255 ]]; then
            tput rc
          fi
        fi
      done
      has_failed && fail_because "Try clearing caches." && exit_with_failure "Tests failed."
      exit_with_success "All tests passed."
      ;;

    "process")
      env=$(get_option 'env')
      if [[ "$env" ]]; then
        if [[ ! -f "$env" ]]; then
          fail_because "$env cannot be read."
        else
          source "$env"
        fi
      fi
      basename=$(get_command_arg 0)
      processor_path="$CONFIG_DIR/processors/$basename"
      [[ ! -f "$processor_path" ]] && fail_because "Missing file processor: $processor"
      has_failed && exit_with_failure
      if [[ "$(path_extension "$processor_path")" == "sh" ]]; then
        echo_title "$(path_unresolve "$CONFIG_DIR" "$processor_path")"
        processor_output=$(cd "$APP_ROOT"; source "$SOURCE_DIR/processor_support.sh"; . "$processor_path")
        [[ $? -ne 0 ]] && fail_because "Processor failed.";
      else
        php_query="autoload=$CONFIG_DIR/processors/&COMMAND=$COMMAND&LOCAL_ENV_ID=$LOCAL_ENV_ID&REMOTE_ENV_ID=$REMOTE_ENV_ID&DATABASE_ID=$DATABASE_ID&DATABASE_NAME=$DATABASE_NAME&FILES_GROUP_ID=$FILES_GROUP_ID&FILEPATH=$FILEPATH&SHORTPATH=$SHORTPATH&IS_WRITEABLE_ENVIRONMENT=$IS_WRITEABLE_ENVIRONMENT"
        echo_title "$(path_unresolve "$CONFIG_DIR" "$processor_path")"
        processor_output=$(cd "$APP_ROOT"; export CLOUDY_CONFIG_JSON; $CLOUDY_PHP "$ROOT/php/class_method_caller.php" "$basename" "$php_query")
        [[ $? -ne 0 ]] && fail_because "Processor failed.";
      fi
      echo $processor_output
      has_failed && exit_with_failure
      exit_with_success
      ;;

    "remote")
      eval $(get_config_as label "environments.$REMOTE_ENV_ID.label")
      echo_title "Connection to $label ($REMOTE_ENV_ID)"
      call_plugin default remote_shell || fail
      has_failed && exit_with_failure
      exit_with_success "You were connected for $(echo_elapsed)"
      ;;

    "db")
      DATABASE_ID=$(get_command_arg 0 "$LOCAL_DATABASE_ID")
      ! DATABASE_ID=$(validate_local_database_id "$DATABASE_ID") && fail_because "$DATABASE_ID" && exit_with_failure
      eval $(get_config_as plugin "environments.$LOCAL_ENV_ID.databases.$DATABASE_ID.plugin")
      echo_title "Enter $LOCAL_ENV_ID database \"$DATABASE_ID\""
      call_plugin $plugin db_shell "$DATABASE_ID" || fail
      has_failed && exit_with_failure
      exit_with_success_elapsed
      ;;

    "export")
      WORKFLOW_ID="$(get_option 'workflow')"
      if [[ ! "$WORKFLOW_ID" ]]; then
        ! WORKFLOW_ID=$(get_workflow_by_command $COMMAND) && fail_because "$WORKFLOW_ID" && exit_with_failure
      fi

      process_in_the_background
      filename=$(get_command_arg 0)
      DATABASE_ID=$(get_option 'id' $LOCAL_DATABASE_ID)

      stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=$COMMAND&TYPE=1&ID=$DATABASE_ID&SOURCE=$LOCAL_ENV_ID"
      time_estimate=$(echo_php_class_method "\AKlump\LiveDevPorter\Statistics::getDuration" "$stat_arguments")
      call_php_class_method "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"

      eval $(get_config_as plugin "environments.$LOCAL_ENV_ID.databases.$DATABASE_ID.plugin")
      if [[ "$JSON_RESPONSE" != true ]]; then
        echo_title "Export $LOCAL_ENV_ID database \"$DATABASE_ID\""
        [[ "$WORKFLOW_ID" ]] && echo_heading "Using workflow: $WORKFLOW_ID"
        [[ "$time_estimate" ]] && echo_heading "Time estimate: $time_estimate"
        echo_time_heading
      fi

      if has_option 'dir'; then
        export_directory="$(get_option 'dir')"
        [[ ! -d "$export_directory" ]] && exit_with_failure "Using --dir requires the directory already exist."
      else
        export_directory="$(database_get_local_directory "$LOCAL_ENV_ID" "$DATABASE_ID")"
      fi
      export_directory_shortpath="$(path_unresolve "$PWD" "$export_directory")"

      table_clear
      # This will create a quick link for the user to "open in Finder"
      table_add_row "export directory" "$export_directory_shortpath"
      [[ "$JSON_RESPONSE" != true ]] && echo && echo_slim_table
      call_plugin $plugin export_db "$DATABASE_ID" "$export_directory" "$filename" || fail
      if has_failed; then
        [[ "$JSON_RESPONSE" == true ]] && exit_with_failure_code_only
        fail_because "$json_output" && exit_with_failure "Failed to export database."
      fi

      if [[ "$WORKFLOW_ID" ]]; then
        execute_workflow_processors "$WORKFLOW_ID" || fail
      fi

      if [[ "$JSON_RESPONSE" == true ]]; then
        has_failed && exit_with_failure_code_only
        json_get
        exit_with_success_code_only
      fi
      has_failed && exit_with_failure "Failed to export database."
      echo_time_heading

      call_php_class_method "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
      exit_with_success_elapsed "Database exported."
    ;;

    "import")
      ! WORKFLOW_ID=$(get_workflow_by_command $COMMAND) && fail_because "$WORKFLOW_ID" && exit_with_failure

      process_in_the_background
      filepath=$(get_command_arg 0)
      DATABASE_ID=$(get_option 'id' $LOCAL_DATABASE_ID)

      eval $(get_config_as plugin "environments.$LOCAL_ENV_ID.databases.$DATABASE_ID.plugin")
      echo_title "Replace Existing Data in $LOCAL_ENV_ID database \"$DATABASE_ID\""
      [[ "$WORKFLOW_ID" ]] && echo_heading "Using workflow: $WORKFLOW_ID"

      # Give the the user a select menu.
      if [[ -f "$filepath" ]]; then
        shortpath=$(path_unresolve "$PWD" "$filepath")
      else
        pull_dir=$(database_get_local_directory "$REMOTE_ENV_ID" "$DATABASE_ID")
        backups_dir=$(database_get_local_directory "$LOCAL_ENV_ID" "$DATABASE_ID")
        table_clear
        table_add_row "$REMOTE_ENV_ID" "$(path_unresolve "$PWD" "$pull_dir")"
        table_add_row "$LOCAL_ENV_ID" "$(path_unresolve "$PWD" "$backups_dir")"
        echo; echo_slim_table

        choose__array=()
        # http://mywiki.wooledge.org/ParsingLs
        for i in "${pull_dir%/}"/*$filepath*.sql*; do
          [[ -f "$i" ]] && choose__array=("${choose__array[@]}" "$(path_unresolve "$PWD" "$i")")
        done
        for i in *$filepath*.sql*; do
          [[ -f "$i" ]] && choose__array=("${choose__array[@]}" "$i")
        done
        for i in "${backups_dir%/}"/*$filepath*.sql*; do
          [[ -f "$i" ]] && choose__array=("${choose__array[@]}" "$(path_unresolve "$PWD" "$i")")
        done
        ! shortpath=$(choose "Type the number of the file to import") && exit_with_failure "Import cancelled."
        filepath=$(path_resolve "${PWD%/}" "$shortpath")
        echo
      fi
      if [[ ! -f "$filepath" ]]; then
        fail_because "$shortpath does not exit"
      else
        stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=$COMMAND&TYPE=1&ID=$DATABASE_ID&SOURCE=$(basename "$filepath")"
        time_estimate=$(echo_php_class_method "\AKlump\LiveDevPorter\Statistics::getDuration" "$stat_arguments")
        call_php_class_method "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"
        [[ "$time_estimate" ]] && echo_heading "Time estimate: $time_estimate"
        echo_time_heading

        # TODO These rollback functions need to be in database.sh
        source "$PLUGINS_DIR/mysql/mysql.sh"
        mysql_create_local_rollback_file "$DATABASE_ID" || fail
        call_plugin $plugin import_db "$DATABASE_ID" "$filepath" || fail
        eval $(get_config_as total_files_to_keep max_database_rollbacks_to_keep 5)
        mysql_prune_rollback_files "$DATABASE_ID" "$total_files_to_keep"
      fi
      if ! has_failed && [[ "$WORKFLOW_ID" ]]; then
        execute_workflow_processors "$WORKFLOW_ID" || fail
      fi
      echo_time_heading
      has_failed && exit_with_failure "Failed to import database."
      call_php_class_method "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
      exit_with_success_elapsed "$shortpath was imported to $DATABASE_ID"
    ;;

    "pull")
      ! WORKFLOW_ID=$(get_workflow_by_command 'pull') && fail_because "$WORKFLOW_ID" && exit_with_failure

      [[ ${#REMOTE_DATABASE_IDS[@]} -eq 0 ]] && has_db=false || has_db=true

      eval $(get_config_as -a file_groups "workflows.$WORKFLOW_ID.file_groups")
      [[ ${#file_groups[@]} -eq 0 ]] && has_files=false || has_files=true

      array_csv__array=()
      [[ "$has_db" == true ]] && [[ "$do_database" == true ]] && array_csv__array=("${array_csv__array[@]}" "databases")
      [[ "$has_files" == true ]] && [[ "$do_files" == true ]] && array_csv__array=("${array_csv__array[@]}" "files")

#      eval $(get_config_as label "environments.$LOCAL_ENV_ID.label")
#      echo_title "$label ($LOCAL_ENV_ID)"

      eval $(get_config_as label "environments.$REMOTE_ENV_ID.label")
      echo_title "Pull $(array_csv --prose) from $label ($REMOTE_ENV_ID)"
      [[ "$WORKFLOW_ID" ]] && echo_heading "Using workflow: $WORKFLOW_ID"

      if [[ "$has_db" == false ]] && [[ "$has_files" == false ]]; then
        fail_because "Nothing to pull; neither \"databases\" nor \"files_group\" have been configured."
      fi

      # Determine the estimated time for all pending tasks.  Note that if we
      # don't have data for only one of the pending tasks, then we will not
      # provide a total estimate, as the estimate would be missing data, hence
      # the provide_estimate variable.
      estimates=''
      provide_estimate=true
      if ! has_failed; then
        if [[ "$do_database" == true ]] && "$has_db" != false ]]; then
          for DATABASE_ID in "${LOCAL_DATABASE_IDS[@]}"; do
            stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=$COMMAND&TYPE=1&ID=$DATABASE_ID&SOURCE=$REMOTE_ENV_ID"
            previous="$(echo_php_class_method "\AKlump\LiveDevPorter\Statistics::getDuration" "$stat_arguments")"
            [[ ! "$previous" ]] && provide_estimate=false && break
            estimates="$estimates,$previous" || estimates="$previous"
          done
        fi
        if [[ "$provide_estimate" == true ]] && [[ "$do_files" == true ]] && "$has_files" != false ]]; then
          eval $(get_config_keys_as group_ids "environments.$LOCAL_ENV_ID.files")
          for FILES_GROUP_ID in ${group_ids[@]} ; do
            has_option group && [[ "$(get_option group)" != "$FILES_GROUP_ID" ]] && continue
            stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=$COMMAND&TYPE=2&ID=$FILES_GROUP_ID&SOURCE=$REMOTE_ENV_ID"
            previous="$(echo_php_class_method "\AKlump\LiveDevPorter\Statistics::getDuration" "$stat_arguments")"
            [[ ! "$previous" ]] && provide_estimate=false && break;
            estimates="$estimates,$previous" || estimates="$previous"
          done
        fi
      fi
      if [[ "$provide_estimate" == true ]]; then
        time_estimate="$(echo_php_class_method "\AKlump\LiveDevPorter\Statistics::sumDurations" "$stat_arguments" "$estimates")"
        [[ "$time_estimate" ]] && echo_heading "Time estimate: $time_estimate"
      fi

      process_in_the_background
      if ! has_failed && [[ "$do_database" == true ]]; then
        if [[ "$has_db" == false ]]; then
          if has_option d; then
            fail_because "Use of -d is out of context; \"databases\" has not been configured."
          elif has_option v; then
            succeed_because "No databases defined; skipping database component."
          fi
        else
          for DATABASE_ID in "${LOCAL_DATABASE_IDS[@]}"; do
            echo_heading "Database: $DATABASE_ID"
            stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=$COMMAND&TYPE=1&ID=$DATABASE_ID&SOURCE=$REMOTE_ENV_ID"
            call_php_class_method "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"

            # This will create a quick link for the user to "open in Finder"
            save_dir=$(database_get_local_directory "$REMOTE_ENV_ID" "$DATABASE_ID")
            backups_dir=$(database_get_local_directory "$LOCAL_ENV_ID" "$DATABASE_ID")
            table_clear
            table_add_row "downloads" "$(path_unresolve "$PWD" "$save_dir")"
            table_add_row "backups" "$(path_unresolve "$PWD" "$backups_dir")"
            echo; echo_slim_table

            echo_red "Press CTRL-C at any time to abort."

            echo_time_heading
            echo
            eval $(get_config_as plugin "environments.$LOCAL_ENV_ID.databases.$DATABASE_ID.plugin")
            ! has_failed && call_plugin $plugin pull_db "$DATABASE_ID" || fail
            ! has_failed && call_php_class_method "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
          done
        fi
      fi

      if ! has_failed && [[ "$do_files" == true ]]; then
        if [[ "$has_files" == false ]]; then
          if has_option f; then
            fail_because "Use of -f is out of context; \"workflows.$WORKFLOW_ID.file_groups\" is empty."
          elif has_option v; then
            succeed_because "No file_groups defined; skipping files component."
          fi
        else
          echo_time_heading
          echo
          eval $(get_config_as plugin "environments.$LOCAL_ENV_ID.plugin")
          call_plugin $plugin pull_files || fail
        fi
      fi
      echo_time_heading
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
