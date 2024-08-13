#!/usr/bin/env bash
#
# @file
# Simplifies the management and transfer of assets between website environments.
#

# Define the configuration file relative to this script.
CLOUDY_PACKAGE_CONFIG="live_dev_porter.core.yml";

# Comment this next line to disable file logging.
[[ "$CLOUDY_LOG" ]] || controller_log="live_dev_porter.log"

# These are globals custom to Live Dev Porter, not to Cloudy.
# TODO These should be namspaced to LDP?
declare -x SOURCE_DIR
declare -x CACHE_DIR
declare -x PLUGINS_DIR

function on_pre_config() {
  source "$CLOUDY_CORE_DIR/inc/config/early.sh"
  SOURCE_DIR="$ROOT/inc"
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
  # We have to trigger all plugins because a plugin may have changed, and if we
  # only triggered active ones, then an inactive plugin will not know to clean
  # up it's generated files, e.g., lando.
  for plugin in "${ALL_PLUGINS[@]}"; do
    plugin_implements "$plugin" clear_cache && call_plugin "$plugin" clear_cache
  done
}

function on_exit_with_success() {
  [[ "$JSON_RESPONSE" == true ]] || return 0
  [[ "" == "$(json_get)" ]] && json_set "{}"
  json_get
  _cloudy_exit
}

function on_exit_with_failure() {
  [[ "$JSON_RESPONSE" == true ]] || return 0
  [[ "" == "$(json_get)" ]] && json_set "{}"
  if [ ${#CLOUDY_FAILURES[@]} -gt 0 ]; then
    json_set_error "${CLOUDY_FAILURES[*]}"
  fi
  json_get
  _cloudy_exit
}

function on_boot() {
  # TODO Search code and replace CACHE_DIR?
  CACHE_DIR="$CLOUDY_CACHE_DIR"
  local _command="$(get_command)"
  local _contents

  # Check if we're trying to initialize -- it will be handled custom below --
  # and if already initialized throw an error.  The only allowable file in the
  # config_dir, before initialization is the cache dir.
  CONFIG_DIR="$CLOUDY_BASEPATH/.live_dev_porter"
  if [[ "init" == "$_command" ]]; then
    CLOUDY_FAILED="Failed to initialize."
    CLOUDY_SUCCESS="Successfully initialized."
    ldp_dir_is_initialized "$PWD" && fail_because "$PWD is already initialized; see $(path_make_pretty "$CONFIG_DIR")" && write_log_error "Init failed because $CONFIG_DIR must not contain any files or folders, except $(path_make_relative "$CLOUDY_CACHE_DIR" "$CONFIG_DIR") when initializing a new project." && exit_with_failure
    return 0
  fi

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
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";CLOUDY_CORE_DIR="$r/cloudy";source "$CLOUDY_CORE_DIR/cloudy.sh";[[ "$ROOT" != "$r" ]] && echo "$(tput setaf 7)$(tput setab 1)Bootstrap failure, cannot load cloudy.sh$(tput sgr0)" && exit 1
# End Cloudy Bootstrap

# Input validation.
validate_input || exit_with_failure "Input validation failed."

COMMAND=$(get_command)
case $COMMAND in
    "clear-cache")
      exit_with_cache_clear
      ;;

    "config-fix")
      # Caching and config changes should usually be handled separately due to
      # their differing needs and impacts on performance. Regenerate config data
      # only when changes occur to the original config.yml to prevent
      # unnecessary system load. However, cache-config synchronicity may require
      # joint management.  The user may want to force a config-derivate file
      # rebuild without editing the configuration files.
      . "$SOURCE_DIR/snippets/_rebuild_config.sh"
      has_failed && exit_with_failure
      exit_with_cache_clear
      ;;

    "version")
      eval $(get_config_as title 'title')
      eval $(get_config_as version 'version')
      echo "$title version $version"
      exit_with_success
      ;;

    "config-migrate")
      echo_title "Migrate from Loft Deploy"
      path_to_loft_deploy=$(get_command_arg 0 "$CLOUDY_BASEPATH/.loft_deploy")
      message="$(. "$PHP_FILE_RUNNER" "$ROOT/php/migrate.php" "$path_to_loft_deploy")" || fail
      has_failed && fail_because "$message" && exit_with_failure "Migration failed."
      succeed_because "$message"
      exit_with_success "Migration complete"
      ;;

    "init")
      handle_init
      has_failed && exit_with_failure
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        plugin_implements $plugin init && call_plugin $plugin init
      done
      has_failed && exit_with_failure
      echo_green_highlight "$CLOUDY_SUCCESS"
      exit_with_cache_clear
      ;;

    "config")
      # If we have two arguments then we are setting a value...
      var_name=$(get_command_arg 0)
      set_value=$(get_command_arg 1)
      if [ "$var_name" ] && [ "$set_value" ]; then
        config_file="$CONFIG_DIR/config.local.yml"
        call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Config\Config::set" "filepath=$config_file&name=$var_name&value=$set_value"
        succeed_because "Config value \"$var_name\" has been set to \"$set_value\"."
        exit_with_cache_clear

      # If we have one, then we are reading...
      elif [ "$var_name" ]; then
        config_file="$CONFIG_DIR/config.local.yml"
        call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Config\Config::get" "filepath=$config_file&name=$var_name"
        exit_with_cache_clear
      fi

      # Otherwise, to the editor.
      editor="$VISUAL"
      if [[ ! "$editor" ]]; then
        editor="${EDITOR:-nano}"
      fi
      config_file="$CONFIG_DIR/config.yml"
      if has_option 'local'; then
        config_file="$CONFIG_DIR/config.local.yml"
      fi
      $editor $config_file && exit_with_cache_clear
      ;;

esac

eval $(get_config_as LOCAL_ENV_ID 'local')
[[ ! "$LOCAL_ENV_ID" ]] && ! ldp_dir_is_initialized "$PWD" && fail_because "Perhaps you have not yet initialized your project?"
exit_with_failure_if_empty_config 'LOCAL_ENV_ID' 'local'

# We will scream if the local base path does not exist, this is because it's
# possible the config is incorrect and we should not allow commands below here
# to be executed in such state.
eval $(get_config_as local_base_path "environments.$LOCAL_ENV_ID.base_path")
if [[ ! -e "$local_base_path" ]]; then
  echo_scream "Configuration \"local: $LOCAL_ENV_ID\" doesn't look right"
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
if [[ 'pull' == $COMMAND ]] || [[ 'push' == $COMMAND ]] || [[ 'remote' == $COMMAND ]] ; then
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

# This is here and not in an event function because we want to ensure the app is
# setup correctly for all scenarios.  In effect we are forcing all traffic
# through this narrow get.
# TODO I wonder if clear-cache should be removed from this?
if [[ "$CLOUDY_CONFIG_HAS_CHANGED" == 'true' ]] && [[ "$COMMAND" != "clear-cache" ]] && [[ "$COMMAND" != "config-fix" ]]; then
  . "$SOURCE_DIR/snippets/_rebuild_config.sh"
fi

# keep this after has changed or the help route will not build
implement_cloudy_basic
implement_route_access

[[ "$(get_option format)" == "json" ]] && JSON_RESPONSE=true

write_log_info "Executing command: $COMMAND"

WORKFLOW_ID="$(get_option 'workflow')"
[[ "$WORKFLOW_ID" ]] || WORKFLOW_ID=$(get_workflow_by_command $COMMAND)
if [[ "$WORKFLOW_ID" ]]; then
  write_log_debug "WORKFLOW_ID=$WORKFLOW_ID"
  ! WORKFLOW_ID=$(validate_workflow "$WORKFLOW_ID") && fail_because "$WORKFLOW_ID" && exit_with_failure
fi

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
      ! has_failed && exit_with_success "All tests passed."
      fail_because "Try config-fix and/or cache-clear and re-test."
      exit_with_failure "Tests failed."
      ;;

    "process")
      if [[ "$WORKFLOW_ID" ]]; then
        WORKFLOW_ID_ARG="$WORKFLOW_ID"
      fi
      env="$CONFIG_DIR/processors/.env"
      if [[ ! -f "$env" ]]; then
        touch "$env"
      fi
      if has_option 'config'; then
        config_file="$CONFIG_DIR/processors/.env"
        $EDITOR $config_file && exit_with_cache_clear
      fi
      source "$env"

      # If provided in the CLI arguments, env must be overwritten.
      [[ "$WORKFLOW_ID_ARG" ]] && WORKFLOW_ID="$WORKFLOW_ID_ARG"

      table_clear
      echo_title "Processor Variables:"
      table_add_row "COMMAND" "$COMMAND"
      table_add_row "LOCAL_ENV_ID" "$LOCAL_ENV_ID"
      table_add_row "REMOTE_ENV_ID" "$REMOTE_ENV_ID"
      table_add_row "DATABASE_ID" "$DATABASE_ID"
      table_add_row "FILES_GROUP_ID" "$FILES_GROUP_ID"
      table_add_row "FILEPATH" "$FILEPATH"
      table_add_row "SHORTPATH" "$SHORTPATH"
      table_add_row "WORKFLOW_ID" "$WORKFLOW_ID"
      echo_slim_table
      echo "Use \"--config\" to change these values."

      if  [[ "$WORKFLOW_ID_ARG" ]]; then
        echo_title "Workflow \"$WORKFLOW_ID\" Uses the Following:"
      else
        echo_title "Select from (Pre)Processors"
      fi

      processor_list=()
      processor=$(get_command_arg 0)
      if [[ ! "$processor" ]]; then
        if [[ "$WORKFLOW_ID_ARG" ]]; then
          eval $(get_config_as -a workflow_preprocessors "workflows.$WORKFLOW_ID.preprocessors")
          eval $(get_config_as -a workflow_processors "workflows.$WORKFLOW_ID.processors")
          processor_list=("${workflow_preprocessors[@]}" "${workflow_processors[@]}")
          choose__array=("${processor_list[@]}" "ALL")
        else
          processor_list=($(. "$PHP_FILE_RUNNER" "$ROOT/php/get_processors.php" "$CONFIG_DIR"))
          choose__array=("${processor_list[@]}")
        fi
        processor=$(choose "Please choose" "CANCEL")
        [ $? -ne 0 ] && succeed_because "You chose to cancel this operation." && exit_with_success
        if [[ "ALL" != "$processor" ]]; then
          processor_list=("$processor")
        fi
      fi

      echo_title "Results"
      for processor in "${processor_list[@]}"; do
        processor_result=''
        processor_output=''
        if [[ "$(path_extension "$processor")" == "sh" ]]; then
          # We can only check for .sh files because the php argument will be
          # "class::method", not the basepath.
          processor_path="$CONFIG_DIR/processors/$processor"
          echo_task "$(path_make_relative "$processor_path" "$CONFIG_DIR")"
          if [[ ! -f "$processor_path" ]]; then
            processor_output="\"$(path_make_relative "$processor_path" "$PWD")\" is not there."
            processor_result=128
          else
            processor_output=$(cd "$CLOUDY_BASEPATH"; source "$SOURCE_DIR/processor_support.sh"; . "$processor_path")
            processor_result=$?
          fi
        else
          echo_task "$processor"
          php_query="autoload=$CONFIG_DIR/processors/&COMMAND=$COMMAND&LOCAL_ENV_ID=$LOCAL_ENV_ID&REMOTE_ENV_ID=$REMOTE_ENV_ID&DATABASE_ID=$DATABASE_ID&DATABASE_NAME=$DATABASE_NAME&FILES_GROUP_ID=$FILES_GROUP_ID&FILEPATH=$FILEPATH&SHORTPATH=$SHORTPATH&IS_WRITEABLE_ENVIRONMENT=$IS_WRITEABLE_ENVIRONMENT"
          processor_class=$(call_php_class_method "\AKlump\LiveDevPorter\Helpers\ResolveClassShortname::__invoke($processor,'\AKlump\LiveDevPorter\Processors')")
          processor_output=$(cd "$CLOUDY_BASEPATH";. "$PHP_FILE_RUNNER" "$ROOT/php/class_method_caller.php" "$processor_class" "$php_query")
          processor_result=$?
        fi

        if [[ "$processor_result" ]]; then
          if [[ $processor_result -eq 255 ]]; then
            echo_task_completed
            succeed_because "$processor exited with 255 -- NOT APPLICABLE."
          elif [[ $processor_result -eq 128 ]]; then
            echo_task_failed
            fail_because "Invalid processor $processor -- NOT FOUND."
          elif [[ $processor_result -ne 0 ]]; then
            echo_task_failed
            fail_because "$processor exited with $processor_result -- FAILED."
          else
            echo_task_completed
          fi
        fi

        if [[ "$processor_output" ]]; then
          echo
          echo "$processor_output"
          echo
        fi
      done
      has_failed && exit_with_failure
      exit_with_success "$exit_message"
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
      write_log_debug "Connecting to database \"$DATABASE_ID\""
      ! DATABASE_ID=$(validate_local_database_id "$DATABASE_ID") && fail_because "$DATABASE_ID" && exit_with_failure
      eval $(get_config_as plugin "environments.$LOCAL_ENV_ID.databases.$DATABASE_ID.plugin")
      echo_title "Enter $LOCAL_ENV_ID database \"$DATABASE_ID\""
      write_log_debug "With plugin: \"$plugin\""
      call_plugin $plugin db_shell "$DATABASE_ID" || fail
      has_failed && fail_because "Try config-fix and then redo." && exit_with_failure "Failed to connect to the database."
      exit_with_success_elapsed
      ;;

    "export")
      process_in_the_background
      filename=$(get_command_arg 0)
      DATABASE_ID=$(get_option 'id' $LOCAL_DATABASE_ID)

      stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=$COMMAND&TYPE=1&ID=$DATABASE_ID&SOURCE=$LOCAL_ENV_ID"
      time_estimate=$(echo_php_class_method "\AKlump\LiveDevPorter\Statistics::getDuration" "$stat_arguments")
      call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"

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
      export_directory_shortpath="$(path_make_pretty "$export_directory")"

      table_clear
      # This will create a quick link for the user to "open in Finder"
      table_add_row "export directory" "$export_directory_shortpath"
      [[ "$JSON_RESPONSE" != true ]] && echo && echo_slim_table
      compress=true
      if has_option "uncompressed"; then
        compress=false
      fi

      force=false
      if has_option "force"; then
        force=true
      fi
      call_plugin $plugin export_db "$DATABASE_ID" "$export_directory" "$compress" "$force" "$filename" || fail
      if has_failed; then
        [[ "$JSON_RESPONSE" == true ]] && exit_with_failure_code_only
        fail_because "$json_output" && exit_with_failure "Failed to export database."
      fi

      if [[ "$WORKFLOW_ID" ]]; then
        execute_workflow_processors "$WORKFLOW_ID" || fail
      fi

      if [[ "$JSON_RESPONSE" == true ]]; then
        write_log_info "$(json_get)"
        ! has_failed && exit_with_success
      fi
      has_failed && exit_with_failure "Failed to export database."
      echo_time_heading

      call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
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
        shortpath=$(path_make_pretty "$filepath")
      else
        pull_dir=$(database_get_local_directory "$REMOTE_ENV_ID" "$DATABASE_ID")
        backups_dir=$(database_get_local_directory "$LOCAL_ENV_ID" "$DATABASE_ID")
        table_clear
        table_add_row "$REMOTE_ENV_ID" "$(path_make_pretty "$pull_dir")"
        table_add_row "$LOCAL_ENV_ID" "$(path_make_pretty "$backups_dir")"
        echo; echo_slim_table

        echo_heading "Sorted newest to oldest by local date"
        echo

        # Get the JSON that represents our import choices.
        json_set "$(. "$PHP_FILE_RUNNER" "$ROOT/php/get_db_dumps.php" "$filepath" "$PWD" "$pull_dir" "$backups_dir")"
        choose__array=()
        choose__labels=()
        for (( i=0; i<$(json_get_value count); i++ )); do
          choose__array=("${choose__array[@]}" "$(json_get_value values.$i)")
          choose__labels=("${choose__labels[@]}" "$(json_get_value labels.$i)")
        done
        ! filepath=$(choose "Pick a file to import") && exit_with_failure "Import cancelled."
        echo
      fi
      if [[ ! -f "$filepath" ]]; then
        fail_because "$shortpath does not exit"
      else
        stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=$COMMAND&TYPE=1&ID=$DATABASE_ID&SOURCE=$(basename "$filepath")"
        time_estimate=$(echo_php_class_method "\AKlump\LiveDevPorter\Statistics::getDuration" "$stat_arguments")
        call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"
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
        execute_workflow_processors "$WORKFLOW_ID" || fail_because "$WORKFLOW_ID failed to process"
      fi
      echo_time_heading
      has_failed && exit_with_failure "Failed to import database."
      call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
      exit_with_success_elapsed "$shortpath was imported to $DATABASE_ID"
    ;;

    "pull")
      [[ ${#REMOTE_DATABASE_IDS[@]} -eq 0 ]] && has_db=false || has_db=true

      eval $(get_config_as -a file_groups "workflows.$WORKFLOW_ID.file_groups")
      [[ ${#file_groups[@]} -eq 0 ]] && has_files=false || has_files=true

      array_csv__array=()
      [[ "$has_db" == true ]] && [[ "$do_database" == true ]] && array_csv__array=("${array_csv__array[@]}" "database(s)")
      [[ "$has_files" == true ]] && [[ "$do_files" == true ]] && array_csv__array=("${array_csv__array[@]}" "files")

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
            call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"

            # This will create a quick link for the user to "open in Finder"
            save_dir=$(database_get_local_directory "$REMOTE_ENV_ID" "$DATABASE_ID")
            backups_dir=$(database_get_local_directory "$LOCAL_ENV_ID" "$DATABASE_ID")
            table_clear
            table_add_row "downloads" "$(path_make_pretty "$save_dir")"
            table_add_row "backups" "$(path_make_pretty "$backups_dir")"
            echo; echo_slim_table

            echo_red "Press CTRL-C at any time to abort."

            echo_time_heading
            echo
            eval $(get_config_as plugin "environments.$LOCAL_ENV_ID.databases.$DATABASE_ID.plugin")
            ! has_failed && call_plugin $plugin pull_db "$DATABASE_ID" || fail
            ! has_failed && call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
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

    "push")
      ! WORKFLOW_ID=$(get_workflow_by_command 'push') && fail_because "$WORKFLOW_ID" && exit_with_failure

      [[ ${#REMOTE_DATABASE_IDS[@]} -eq 0 ]] && has_db=false || has_db=true

      eval $(get_config_as -a file_groups "workflows.$WORKFLOW_ID.file_groups")
      [[ ${#file_groups[@]} -eq 0 ]] && has_files=false || has_files=true

      array_csv__array=()
      [[ "$has_db" == true ]] && [[ "$do_database" == true ]] && array_csv__array=("${array_csv__array[@]}" "database(s)")
      [[ "$has_files" == true ]] && [[ "$do_files" == true ]] && array_csv__array=("${array_csv__array[@]}" "files")

      eval $(get_config_as label "environments.$REMOTE_ENV_ID.label")
      echo_title "Push local $(array_csv --prose) to $label ($REMOTE_ENV_ID)"
      [[ "$WORKFLOW_ID" ]] && echo_heading "Using workflow: $WORKFLOW_ID"

      if [[ "$has_db" == false ]] && [[ "$has_files" == false ]]; then
        fail_because "Nothing to push; neither \"databases\" nor \"files_group\" have been configured."
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
            call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"

            echo_red "Press CTRL-C at any time to abort."

            echo_time_heading
            echo
            eval $(get_config_as plugin "environments.$LOCAL_ENV_ID.databases.$DATABASE_ID.plugin")
            ! has_failed && call_plugin $plugin push_db "$DATABASE_ID" || fail
            ! has_failed && call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
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
          call_plugin $plugin push_files || fail
        fi
      fi
      echo_time_heading
      has_failed && exit_with_failure
      exit_with_success_elapsed
    ;;

    "info")
      source "$SOURCE_DIR/commands/info.sh"
      for plugin in "${ACTIVE_PLUGINS[@]}"; do
        plugin_implements $plugin info && call_plugin $plugin info
      done
      has_failed && exit_with_failure
      exit_with_success "Use 'help' to see all commands."
    ;;

esac

throw "Unhandled command \"$COMMAND\"."
