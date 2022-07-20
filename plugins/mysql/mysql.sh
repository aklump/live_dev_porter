#!/usr/bin/env bash

# Remove the mysql.*.cnf files from the cache directory
#
# Returns 0 if successful, 1 otherwise.
function mysql_on_clear_cache() {
  database_delete_all_defaults_files
}

# Rebuild configuration files after a cache clear.
# # TODO This is not working because additional config is not merging correctly in the cloudy cc.
#
# Returns 0 if successful, 1 otherwise.
function mysql_on_rebuild_config() {
  eval $(get_config_keys_as "database_ids" "environments.$LOCAL_ENV_ID.databases")
  for database_id in "${database_ids[@]}"; do
    local db_pointer="environments.$LOCAL_ENV_ID.databases.${database_id}"

    eval $(get_config_as "plugin" "$db_pointer.plugin")
    [[ "$plugin" != 'mysql' ]] && continue;

    eval $(get_config_as "host" "$db_pointer.host" "localhost")
    eval $(get_config_as "protocol" "$db_pointer.protocol")
    eval $(get_config_as "port" "$db_pointer.port")

    eval $(get_config_as "database" "$db_pointer.database")
    exit_with_failure_if_empty_config "database" "$db_pointer.database"

    eval $(get_config_as "password" "$db_pointer.password")
    exit_with_failure_if_empty_config "password" "$db_pointer.password"

    eval $(get_config_as "user" "$db_pointer.user")
    exit_with_failure_if_empty_config "user" "$db_pointer.user"

    local filepath=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
    local path_label="$(path_unresolve "$APP_ROOT" "$filepath")"

    # Create the .cnf file
    local directory=""$(dirname "$filepath")""
    sandbox_directory "$directory"
    ! mkdir -p "$directory" && fail_because "Could not create $directory" && return 1
    ! touch "$filepath" && fail_because "Could not create $path_label" && return 1
    ! chmod 0600 "$filepath" && fail_because "Failed with chmod 0600 $path_label" && return 1

    echo "[client]" >"$filepath"
    echo "host=\"$host\"" >>"$filepath"
    [[ "$port" ]] && echo "port=\"$port\"" >>"$filepath"
    echo "user=\"$user\"" >>"$filepath"
    echo "password=\"$password\"" >>"$filepath"
    echo "protocol=\"${protocol:-tcp}\"" >>"$filepath"
    ! chmod 0400 "$filepath" && fail_because "Failed with chmod 0400 $path_label" && return 1

  done
  has_failed && return 1
  succeed_because "$path_label has been created."
  return 0
}

# @see database_get_name
function mysql_on_database_name() {
    local environment_id="$1"
    local database_id="$2"

    eval $(get_config_as "db_name" "environments.$environment_id.databases.$database_id.database")
    [[ "$db_name" ]] && echo "$db_name" && return 0
    echo "The database ID \"$database_id\" is not in the \"$environment_id\" environment configuration."
    return 1
}

# Add database configuration tests to the execution
#
# Returns nothing.
function mysql_on_configtest() {
  local defaults_file
  local db_name
  local message
  for database_id in "${LOCAL_DATABASE_IDS[@]}"; do
    defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
    ! db_name=$(database_get_name "$LOCAL_ENV_ID" "$database_id") && echo_fail "$db_name" && fail
    echo_task "Able to connect to $LOCAL_ENV_ID database: $database_id."
    if mysql --defaults-file="$defaults_file" "$db_name" -e ";" 2> /dev/null ; then
      echo_task_completed
    else
      echo_task_failed
      fail
    fi
  done

  # Check if remote has an export tool installed.
  if [[ "$REMOTE_ENV_ID" != null ]]; then
    remote_base_path="$(environment_path_resolve $REMOTE_ENV_ID)"
    echo_task "Ensure remote has export tool installed."
    if remote_ssh "[[ -e "$remote_base_path"/vendor/bin/ldp ]] || [[ -e "$remote_base_path"/vendor/bin/loft_deploy.sh ]]"  &> /dev/null; then
      echo_task_completed
    else
      echo_task_failed
      fail
    fi
  fi
}

# Enter a local database shell
#
# $1 - The local database ID to use.
#
# Returns 0 if .
function mysql_on_db_shell() {
  local database_id="$1"

  local defaults_file
  local db_name
  ! db_name=$(database_get_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1
  defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$LOCAL_DATABASE_ID")
  mysql --defaults-file="$defaults_file" "$db_name"
}

# Delete the oldest files up to a count.
#
# $1 - The database ID.
# $2 - The total newest files to keep, e.g. 5
#
# Returns 1 if failed.
function mysql_prune_rollback_files() {
  local database_id="$1"
  local keep_files_count=$2
  [[ "$2" ]] || return 1
  filename="rollback_$(date8601 -c).sql"
  dumpfiles_dir="$(database_get_dumpfiles_directory "$LOCAL_ENV_ID" "$database_id")"

  local rollback_files
  local stop_at_index
  rollback_files=()
  for i in "$dumpfiles_dir/rollback_"*.sql*; do
    rollback_files=("${rollback_files[@]}" "$i")
  done

  stop_at_index=$((${#rollback_files[@]}-$keep_files_count))
  echo_task "Delete all but $keep_files_count most recent backups."
  for (( i = 0; i < $stop_at_index; i++ )); do
    sandbox_directory "$(dirname "${rollback_files[i]}")"
    ! rm "${rollback_files[i]}" && echo_task_failed && return 1
  done
  echo_task_completed
  return 0
}

# Create a database archive for rollback
#
# $1 - The database ID.
#
# Returns 0 if file was created, 1 otherwise.
function mysql_create_local_rollback_file() {
  local database_id="$1"

  local filename
  local db_name
  local defaults_file
  local dumpfiles_dir
  local options
  local save_as

  filename="rollback_$(date8601 -c).sql"
  dumpfiles_dir="$(database_get_dumpfiles_directory "$LOCAL_ENV_ID" "$database_id")"
  sandbox_directory "$dumpfiles_dir"
  ! mkdir -p "$dumpfiles_dir" && fail_because "Could not create directory: $dumpfiles_dir" && return 1

  # @link https://dev.mysql.com/doc/refman/5.7/en/mysqldump.html#mysqldump-option-summary
  eval $(get_config_as -a "mysqldump_base_options" "plugins.mysql.mysqldump_base_options")
  options=' --add-drop-table'
  if [[ null != ${mysqldump_base_options[@]} ]]; then
    for option in ${mysqldump_base_options[@]}; do
      options="$options --$option"
    done
  fi

  defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
  ! db_name=$(database_get_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1
  write_log_debug "mysqldump --defaults-file="$defaults_file"$options "$db_name"  >> "${dumpfiles_dir%/}/$filename""
  echo_task "Backup local database to: $filename"
  if ! mysqldump --defaults-file="$defaults_file"$options "$db_name"  > "${dumpfiles_dir%/}/$filename"; then
    echo_task_failed && fail_because "mysqldump failed." && return 1
  fi
  echo_task_completed
  return 0
}

# Handle a database export.
#
# $1 - The database ID
# $2 - Optional, base name to use instead of default.
#
# Returns 0 if .
function mysql_on_export_db() {
  local database_id="$1"
  local filename="$2"

  local dumpfiles_dir="$(database_get_dumpfiles_directory "$LOCAL_ENV_ID" "$database_id")"
  [[ "$filename" ]] || filename="${LOCAL_ENV_ID}_${database_id}_$(date8601 -c)"
  local save_as="$dumpfiles_dir/$filename.sql"

  # Ensure we don't clobber an existing.
  [[ -f "$save_as" ]] && fail_because "$save_as already exists." && return 1

  sandbox_directory "$dumpfiles_dir"
  ! mkdir -p "$dumpfiles_dir" && fail_because "Could not create directory: $dumpfiles_dir" && return 1

  # @link https://dev.mysql.com/doc/refman/5.7/en/mysqldump.html#mysqldump-option-summary
  eval $(get_config_as -a "mysqldump_base_options" "plugins.mysql.mysqldump_base_options")

  local shared_options=''
  if [[ null != ${mysqldump_base_options[@]} ]]; then
    for option in ${mysqldump_base_options[@]}; do
      shared_options=" $shared_options --$option"
    done
  fi

  local options=''
  local defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
  local db_name
  local structure_tables
  local data_tables

  ! db_name=$(database_get_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1

  # This will write the table structure to the export file.
  structure_tables=($(database_get_export_tables --structure "$LOCAL_ENV_ID" "$database_id" "$db_name" "$WORKFLOW_ID"))
  if [[ "$structure_tables" ]]; then
    options="$shared_options --add-drop-table --no-data "
    write_log_debug "mysqldump --defaults-file="$defaults_file"$options "$db_name" $structure_tables >> "$save_as""
    mysqldump --defaults-file="$defaults_file"$options "$db_name" ${structure_tables[*]} >> "$save_as" || return 1
    succeed_because "Structure for ${#structure_tables[@]} table(s) exported."
  fi
  # This will write the data to the export file.
  data_tables=($(database_get_export_tables --data "$LOCAL_ENV_ID" "$database_id" "$db_name" "$WORKFLOW_ID"))

  if [[ "$data_tables" ]]; then
    options="$shared_options --skip-add-drop-table --no-create-info"
    write_log_debug "mysqldump --defaults-file="$defaults_file"$options "$db_name" $data_tables >> "$save_as""
    mysqldump --defaults-file="$defaults_file"$options "$db_name" ${data_tables[*]} >> "$save_as" || return 1
    succeed_because "Data for ${#data_tables[@]} table(s) exported."
  else
    succeed_because "No table data has been exported."
  fi

  if [[ ! "$structure_tables" ]] && [[ ! "$data_tables" ]]; then
    fail_because "The configuration has excluded both database structure and data."
    fail_because "A database export file was not created."
  fi

  ! gzip -f "$save_as" && fail_because "Could not compress dumpfile"

  has_failed && return 1
  [[ "$JSON" ]] && echo "$save_as"
  succeed_because "Saved in: $(dirname "$save_as")"
  succeed_because "Filename is: $(basename "$save_as")"
}

function mysql_on_import_db() {
  local database_id="$1"
  local filepath="$2"

  local db_name
  local defaults_file
  defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
  ! db_name=$(database_get_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1
  mysql_drop_all_tables "$DATABASE_ID" || return 1

  if [[ "$(path_extension "$filepath")" == 'gz' ]]; then
    echo_task "Decompress file."
    ! gunzip -f "$filepath" && echo_task_failed && return 1
    filepath=${filepath%.*}
    echo_task_completed
  fi

  echo_task "Import data from $(basename "$filepath")"
  write_log_debug "mysql --defaults-file="$defaults_file" $db_name < $filepath"
  ! mysql --defaults-file="$defaults_file" $db_name < $filepath && echo_task_failed && return 1
  echo_task_completed

  return 0;
}

# Drop all local database tables for given database.
#
# $1 - The database ID.
#
# Returns 0 if successful; 1 otherwise.
function mysql_drop_all_tables() {
  local database_id="$1"

  local db_name
  local tables
  local sql

  echo_task "Drop all tables."
  ! db_name=$(database_get_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1
  tables=$(mysql --defaults-file="$defaults_file" $db_name -e 'SHOW TABLES' | awk '{ print $1}' | grep -v '^Tables')
  [[ ! "${tables[0]}" ]] && echo_task_completed && return 0

  sql="DROP TABLE "
  for t in $tables; do
    sql="$sql\`$t\`,"
  done
  sql="${sql%,}"

  write_log_debug "mysql --defaults-file="$defaults_file" $db_name -e "$sql""
  ! mysql --defaults-file="$defaults_file" $db_name -e "$sql" && echo_task_failed && return 1
  echo_task_completed
  return 0
}

function mysql_on_pull_db() {
  local DATABASE_ID="$1"

  local remote_base_path
  local remote_dumpfile_path
  local ldp_fetch_options

  # Create the export at the remote.
  echo_task "Export remote database: $DATABASE_ID."
  ! WORKFLOW_ID=$(get_workflow_by_command 'pull') && fail_because "$WORKFLOW_ID" && exit_with_failure
  [[ "$WORKFLOW_ID" ]] && ldp_fetch_options=" --workflow="$WORKFLOW_ID""

  remote_base_path="$(environment_path_resolve $REMOTE_ENV_ID)"
  write_log_debug "remote_ssh \"(cd $remote_base_path || exit 1;if [[ -e ./vendor/bin/ldp ]]; then ./vendor/bin/ldp export pull --json --id="$DATABASE_ID"$ldp_options; elif [[ -e ./vendor/bin/loft_deploy.sh ]]; then ./vendor/bin/loft_deploy.sh export pull -y; else exit 1; fi)\""
  ! remote_ssh "(cd $remote_base_path || exit 1;if [[ -e ./vendor/bin/ldp ]]; then ./vendor/bin/ldp export pull --json --id="$DATABASE_ID"$ldp_options; elif [[ -e ./vendor/bin/loft_deploy.sh ]]; then ./vendor/bin/loft_deploy.sh export pull -y; else exit 1; fi)" &> /dev/null && echo_task_failed && fail_because "No export tool installed on the remote environment. This can also happen if execute permissions are incorrect." && return 1
  echo_task_completed
  remote_dumpfile_path="$remote_base_path/private/default/db/purgeable/aurora_timesheet_drupal-pull.sql.gz"

  # Create the local destination...
  local dumpfiles_dir="$(database_get_dumpfiles_directory "$REMOTE_ENV_ID" "$DATABASE_ID")"
  sandbox_directory "$dumpfiles_dir"
  ! mkdir -p "$dumpfiles_dir" && fail_because "Could not create directory: $dumpfiles_dir" && return 1

  # Download the dumpfile.
  local save_as="$dumpfiles_dir/$(basename "$remote_dumpfile_path")"
  echo_task "Download as $(basename "$save_as")"
  ! scp ${REMOTE_ENV_AUTH}:$remote_dumpfile_path "$save_as" &> /dev/null && echo_task_failed && return 1
  echo_task_completed

  # Do the rollback and import.
  mysql_create_local_rollback_file "$DATABASE_ID" || return 1
  mysql_on_import_db "$DATABASE_ID" "$save_as" || return 1
  eval $(get_config_as total_files_to_keep max_database_rollbacks_to_keep 5)
  mysql_prune_rollback_files "$DATABASE_ID" "$total_files_to_keep" || return 1

  ! WORKFLOW_ID=$(get_workflow_by_command 'pull') && fail_because "$WORKFLOW_ID" && exit_with_failure
  if [[ "$WORKFLOW_ID" ]]; then
    ENVIRONMENT_ID="$LOCAL_ENV_ID"
    execute_workflow_processors "$WORKFLOW_ID" || fail
  fi
}
