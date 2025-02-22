##
 # Get the backup filepath for a given database.
 #
 # @param string The environment ID
 # @param string The database ID
 #
 # @echo The path setting for the database, if using backups plugin.
 # @return 1 If not using the backups plugin for the env's DB.
 # @return 2 If the path is empty
 # @return 3 If the path is in config, but file doesn't exist.
 ##
function backups_get_database_filepath() {
  local environment_id="$1"
  local database_id="$2"

  local plugin
  local backups_db_path

  eval $(get_config_as "plugin" "environments.$environment_id.plugin")
  [[ "$plugin" != 'backups' ]] && return 1
  eval $(get_config_path_as "backups_db_path" "environments.$environment_id.databases.${database_id}.path")
  [[ ! "$backups_db_path" ]] && return 2
  [[ ! -f "$backups_db_path" ]] && echo "$backups_db_path" && return 3
  echo "$backups_db_path" && return 0
}

##
 # Event handler for "configtest"
 #
 # @echo Test results.
 # @return 0
 ##
function backups_on_configtest() {
  local database_id
  local backups_db_path

  for database_id in "${REMOTE_DATABASE_IDS[@]}"; do
    database_filepath=$(backups_get_database_filepath "$REMOTE_ENV_ID" "$database_id")
    if [[ "$database_filepath" ]]; then
      echo_task "Remote DB exists: $(path_make_pretty "$database_filepath")"
      if [ ! -f "$database_filepath" ]; then
        echo_task_failed && fail
      else
        echo_task_completed
      fi
    fi
  done
  for database_id in "${LOCAL_DATABASE_IDS[@]}"; do
    database_filepath=$(backups_get_database_filepath "$LOCAL_ENV_ID" "$database_id")
    if [[ "$database_filepath" ]]; then
      echo_task "Local DB exists: $(path_make_pretty "$database_filepath")"
      if [ ! -f "$database_filepath" ]; then
        echo_task_failed && fail
      else
        echo_task_completed
      fi
    fi
  done
}

##
 # Event handler for "pull_db"
 #
 # @param string The database ID to pull from.
 #
 # @echo
 # @return 0
 ##
function backups_on_pull_db() {
  local DATABASE_ID="$1"

  local database_filepath
  local cp
  local result
  local dumpfiles_dir
  local destination_directory
  local save_as

  eval $(get_config_as cp shell_commands.cp)

  write_log_debug "backups_on_pull_db() called."

  database_filepath=$(backups_get_database_filepath "$REMOTE_ENV_ID" "$DATABASE_ID")
  write_log_debug "$database_filepath"
  result=$?

  [[ "$result" -eq 2 ]] && fail_because "environments.$REMOTE_ENV_ID.databases.$DATABASE_ID.path cannot be empty"
  [[ "$result" -eq 3 ]] && fail_because "environments.$REMOTE_ENV_ID.databases.$DATABASE_ID.path" && fail_because "$database_filepath does not exist"
  has_failed && return 1

  echo_task "Copying database: $DATABASE_ID"
  if [[ "$WORKFLOW_ID" ]]; then
    execute_workflow_processors "$WORKFLOW_ID" "preprocessors" || fail
  fi

  # Create the local destination for the dumpfile, doing this first allows the
  # user output to be a valid link in some terminals so keep it first in the
  # process.  That way the user can click the link and open the directory and
  # watch the file download into it.
  dumpfiles_dir="$(database_get_local_directory "$REMOTE_ENV_ID" "$DATABASE_ID")"
  sandbox_directory "$dumpfiles_dir"
  ! mkdir -p "$dumpfiles_dir" && fail_because "Could not create directory: $dumpfiles_dir" && return 1

  # Copy the dumpfile.
  echo_task "Save dumpfile as $(basename "$database_filepath")"
  destination_directory="$dumpfiles_dir/"
  if has_option "verbose"; then
    echo "$cp "$database_filepath" "$destination_directory""
    ! $cp "$database_filepath" "$destination_directory" && echo_task_failed && return 1
  else
    ! $cp "$database_filepath" "$destination_directory"  && echo_task_failed && return 1
  fi
  write_log_debug "Copied to $destination_directory"
  echo_task_completed
  echo_time_heading

  do_backup=true
  if has_option 'skip-local-backup'; then
    do_backup=false
    ! confirm --caution "Skipping local backup, are you sure?" && fail_because "You stopped the operation, remove --skip-local-backup and try again." && return 1
  fi

  load_plugin "mysql"

  if [[ "$do_backup" == true ]]; then
    mysql_create_local_rollback_file "$DATABASE_ID" || return 1
  fi

  save_as="$dumpfiles_dir/$(basename "$database_filepath")"
  mysql_on_import_db "$DATABASE_ID" "$save_as" || return 1
  echo_time_heading
  eval $(get_config_as total_files_to_keep max_database_rollbacks_to_keep 15)
  mysql_prune_rollback_files "$DATABASE_ID" "$total_files_to_keep" || return 1

  # Handle deleting the dumpfile if configured so.
  eval $(get_config_as delete "delete_pull_dumpfiles" true)
  if [[ "$delete" == true ]]; then
    echo_task "Delete dumpfile"
    save_as="$(dirname "$save_as")/$(basename "${save_as/.sql.gz/.sql}")"
    sandbox_directory "$(dirname "$save_as")"
    ! rm "$save_as" && echo_task_failed && return 1
    echo_task_completed
  fi

  if [[ "$WORKFLOW_ID" ]]; then
    execute_workflow_processors "$WORKFLOW_ID" || fail
  fi

  return 0
}
