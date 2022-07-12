#!/usr/bin/env bash

# Remove the mysql.*.cnf files from the cache directory
#
# Returns 0 if successful, 1 otherwise.
function mysql_on_clear_cache() {
  local pattern=$(database_get_defaults_file "*" "*")
  for filepath in $pattern; do
    [[ ! -f "$filepath" ]] && continue
    sandbox_directory "$(dirname $filepath)"
    if chmod 0600 "$filepath" && rm "$filepath"; then
      succeed_because "$(path_unresolve "$APP_ROOT" "$filepath")"
    else
      fail_because "Failed to delete $filepath"
    fi
  done
  has_failed && return 1
  return 0
}

# Rebuild configuration files after a cache clear.
#
# Returns 0 if successful, 1 otherwise.
function mysql_rebuild_config() {
  for environment_id in "${ENVIRONMENT_IDS[@]}"; do
    eval $(get_config_keys_as "database_ids" "environments.$environment_id.databases")
    for database_id in "${database_ids[@]}"; do
      eval $(get_config_as "plugin" "environments.$environment_id.databases.${database_id}.plugin")
      [[ "$plugin" != 'mysql' ]] && continue;

      local db_pointer="environments.$environment_id.databases.${database_id}"
      eval $(get_config_as "host" "$db_pointer.host" "localhost")
      eval $(get_config_as "port" "$db_pointer.port")

      eval $(get_config_as "name" "$db_pointer.name")
      exit_with_failure_if_empty_config "name" "$db_pointer.name"

      eval $(get_config_as "password" "$db_pointer.password")
      exit_with_failure_if_empty_config "password" "$db_pointer.password"

      eval $(get_config_as "user" "$db_pointer.user")
      exit_with_failure_if_empty_config "user" "$db_pointer.user"

      local filepath=$(database_get_defaults_file "$environment_id" "$database_id")
      local path_label="$(path_unresolve "$APP_ROOT" "$filepath")"

      # Create the .cnf file
      local directory=""$(dirname "$filepath")""
      sandbox_directory "$directory"
      ! mkdir -p "$directory" && fail_because "Could not create $directory" && return 1
      ! touch "$filepath" && fail_because "Could not create $path_label" && return 1
      ! chmod 0600 "$filepath" && fail_because "Failed with chmod 0600 $path_label" && return 1

      echo "[client]" >>"$filepath"
      echo "host=\"$host\"" >>"$filepath"
      [[ "$port" ]] && echo "port=\"$port\"" >>"$filepath"
      echo "user=\"$user\"" >>"$filepath"
      echo "password=\"$password\"" >>"$filepath"
      [[ "$protocol" ]] && echo "protocol=\"$protocol\"" >>"$filepath"
      ! chmod 0400 "$filepath" && fail_because "Failed with chmod 0400 $path_label" && return 1

    done
  done
  has_failed && return 1
  succeed_because "$path_label has been created."
  return 0
}

# Echo the database name by environment ID && database ID.
#
# $1 - The environment ID.
# $1 - The database ID.
#
# @code
# local name
# ! name=$(mysql_get_env_db_name_by_id "$LOCAL_ENV_ID" "$database_id") && fail_because "$name" && return 1
# @endcode
#
# Returns 0 if .
function mysql_get_env_db_name_by_id() {
  local environment_id="$1"
  local database_id="$2"

  eval $(get_config_as "db_name" "environments.$environment_id.databases.$database_id.name")
  [[ "$db_name" ]] && echo "$db_name" && return 0
  echo "The database ID \"$database_id\" is not in the \"$environment_id\" environment configuration."
  return 1
}

# Add database configuration tests to the execution
#
# Returns nothing.
function mysql_configtest() {
  local defaults_file
  local db_name
  local message
  for database_id in "${LOCAL_DATABASE_IDS[@]}"; do
    defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
    ! db_name=$(mysql_get_env_db_name_by_id "$LOCAL_ENV_ID" "$database_id") && echo_fail "$db_name" && fail
    message="Able to connect to $LOCAL_ENV_ID database: $database_id."
    if mysql --defaults-file="$defaults_file" "$db_name" -e ";" 2> /dev/null ; then
      echo_pass "$message"
    else
      echo_fail "$message" && fail
    fi
  done
}

# Enter a local database shell
#
# $1 - The local database ID to use.
#
# Returns 0 if .
function mysql_db_shell() {
  local database_id="$1"

  local defaults_file
  local db_name
  ! db_name=$(mysql_get_env_db_name_by_id "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1
  defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$LOCAL_DATABASE_ID")
  mysql --defaults-file="$defaults_file" "$db_name"
}

# Handle a database export.
#
# $1 - The database ID
# $2 - Optional, base name to use instead of default.
#
# Returns 0 if .
function mysql_export_db() {
  local database_id="$1"
  local basename="$3"

  [[ "$database_id" ]] || database_id="$LOCAL_DATABASE_ID"

  local export_dir="$(database_get_export_directory "$LOCAL_ENV_ID" "$database_id")"
  [[ "$basename" ]] || basename="${LOCAL_ENV_ID}_${database_id}_$(date8601 -c)"
  local save_as="${export_dir%/}/$basename.sql"

  # Ensure we don't clobber an existing.
  [[ -f "$save_as" ]] && fail_because "$save_as already exists." && return 1

  sandbox_directory "$export_dir"
  ! mkdir -p "$export_dir" && fail_because "Could not create directory: $save_as" && return 1

  # @link https://dev.mysql.com/doc/refman/5.7/en/mysqldump.html#mysqldump-option-summary
  eval $(get_config_as -a "settings" "environments.$LOCAL_ENV_ID.databases.$database_id.mysqldump_options")

  local shared_options=''
  if [[ null != ${settings[@]} ]]; then
    for option in ${settings[@]}; do
      shared_options=" $shared_options --$option"
    done
  fi

  local options=''
  local defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
  local db_name
  local structure_tables
  local data_tables

  ! db_name=$(mysql_get_env_db_name_by_id "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1

  # This will write the table structure to the export file.
  structure_tables=($(database_get_export_tables --structure "$LOCAL_ENV_ID" "$database_id" "$db_name" "$WORKFLOW_ID"))
  if [[ "$structure_tables" ]]; then
    options="$shared_options --add-drop-table --no-data "
    write_log_debug "mysqldump --defaults-file="$defaults_file"$options "$db_name" $structure_tables >> "$save_as""
    succeed_because "Structure for ${#structure_tables[@]} table(s) exported."
    mysqldump --defaults-file="$defaults_file"$options "$db_name" ${structure_tables[*]} >> "$save_as"
  fi

  # This will write the data to the export file.s
  data_tables=($(database_get_export_tables --data "$LOCAL_ENV_ID" "$database_id" "$db_name" "$WORKFLOW_ID"))

  if [[ "$data_tables" ]]; then
    options="$shared_options --skip-add-drop-table --no-create-info"
    write_log_debug "mysqldump --defaults-file="$defaults_file"$options "$db_name" $data_tables >> "$save_as""
    succeed_because "Data for ${#data_tables[@]} table(s) exported."
    mysqldump --defaults-file="$defaults_file"$options "$db_name" ${data_tables[*]} >> "$save_as"
  else
    succeed_because "No table data has been exported."
  fi

  if [[ ! "$structure_tables" ]] && [[ ! "$data_tables" ]]; then
    fail_because "The configuration has excluded both database structure and data."
    fail_because "A database export file was not created."
  fi

  has_failed && return 1
  succeed_because "Saved in: $(dirname "$save_as")"
  succeed_because "Filename is: $(basename "$save_as")"
}

function mysql_import_db() {
  local path_to_dumpfile="$1"

  if [[ ! "$path_to_dumpfile" ]]; then
    fail_because "No import filename given." && return 1
  fi
  if [ ! -f "$path_to_dumpfile" ]; then
    fail_because "Import file \"$path_to_dumpfile\" does not exist." && return 1
  fi

  eval $(get_config_as "db_name" "environments.dev.database.name")

  local defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$LOCAL_DATABASE_ID")

  mysql --defaults-file="$defaults_file" $db_name < $path_to_dumpfile
}

function mysql_pull_dbs() {
  for DATABASE_ID in "${LOCAL_DATABASE_IDS[@]}"; do

    # TODO Export remote database.
    # TODO Download remote database.
    # TODO Export local database for rollback.
    # TODO Import Remote database to local database

    continue;

    if [[ "$WORKFLOW_ID" ]]; then
      ENVIRONMENT_ID="$LOCAL_ENV_ID"
#      eval $(get_config_as -a includes "file_groups.${key}.include")
#      for include in "${includes[@]}"; do
#        for FILEPATH in "$destination"/$include; do
#          if [[ -f "$FILEPATH" ]]; then
#            SHORTPATH=$(path_unresolve "$destination" "$FILEPATH")
#            SHORTPATH=${SHORTPATH#/}
#            execute_workflow "$workflow" || exit_with_failure
#          fi
#         done
#      done
    fi
  done
}
