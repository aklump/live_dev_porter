#!/usr/bin/env bash

# Remove the mysql.*.cnf files from the cache directory
#
# Returns 0 if successful, 1 otherwise.
function mysql_on_clear_cache() {
  local pattern=$(ldp_db_echo_conf_filepath "*" "*")
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
  eval $(get_config_keys_as 'keys' "environments")
  for key in "${keys[@]}"; do
    eval $(get_config_keys_as "database_ids" "environments.${key}.databases")
    for database_id in "${database_ids[@]}"; do
      eval $(get_config_as "plugin" "environments.${key}.databases.${database_id}.plugin")
      [[ "$plugin" != 'mysql' ]] && continue;

      local db_pointer="environments.${key}.databases.${database_id}"
      eval $(get_config_as "host" "$db_pointer.host" "localhost")
      eval $(get_config_as "port" "$db_pointer.port")

      eval $(get_config_as "name" "$db_pointer.name")
      exit_with_failure_if_empty_config "name" "$db_pointer.name"

      eval $(get_config_as "password" "$db_pointer.password")
      exit_with_failure_if_empty_config "password" "$db_pointer.password"

      eval $(get_config_as "user" "$db_pointer.user")
      exit_with_failure_if_empty_config "user" "$db_pointer.user"

      eval $(get_config_as "environment_id" "environments.${key}.id")
      local filepath=$(ldp_db_echo_conf_filepath "$environment_id" "$database_id")
      local path_label="$(path_unresolve "$APP_ROOT" "$filepath")"

      # Create the .cnf file
      local directory=""$(dirname "$filepath")""
      sandbox_directory "$directory"
      ! mkdir -p "$directory" && fail_because "Could not create $directory" && return 1
      ! touch "$filepath" && fail_because "Could not create $path_label" && return 1
      ! chmod 0600 "$filepath" && fail_because "Failed with chmod 0600 $path_label" && return 1

      echo "# AUTOGENERATED, DO NOT EDIT!" >"$filepath"
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
# ! name=$(mysql_get_database_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$name" && return 1
# @endcode
#
# Returns 0 if .
function mysql_get_database_name() {
  local environment_id="$1"
  local database_id="$2"

  local key=$(echo_config_key_by_id "environments" "$environment_id")
  eval $(get_config_as "db_name" "environments.$key.databases.$database_id.name")
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
  eval $(get_config_keys_as "database_ids" "environments.$LOCAL_ENV_KEY.databases")
  for database_id in "${database_ids[@]}"; do
    defaults_file=$(ldp_db_echo_conf_filepath "$LOCAL_ENV_ID" "$database_id")
    ! db_name=$(mysql_get_database_name "$LOCAL_ENV_ID" "$database_id") && echo_fail "$db_name" && fail
    message="Can connect to $LOCAL_ENV_ID database: $database_id."
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
  ! db_name=$(mysql_get_database_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1
  defaults_file=$(ldp_db_echo_conf_filepath "$LOCAL_ENV_ID" "$LOCAL_DATABASE_ID")
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
  local basename="$2"

  [[ "$database_id" ]] || database_id="$LOCAL_DATABASE_ID"

  local export_dir="$(ldp_db_echo_export_directory "$LOCAL_ENV_ID" "$database_id")"
  [[ "$basename" ]] || basename="${LOCAL_ENV_ID}_${database_id}_$(date8601 -c)"
  local save_as="${export_dir%/}/$basename.sql"

  # Ensure we don't clobber an existing.
  [[ -f "$save_as" ]] && fail_because "$save_as already exists." && return 1

  sandbox_directory "$export_dir"
  ! mkdir -p "$export_dir" && fail_because "Could not create directory: $save_as" && return 1

  # @link https://dev.mysql.com/doc/refman/5.7/en/mysqldump.html#mysqldump-option-summary
  eval $(get_config_as -a "settings" "environments.$LOCAL_ENV_KEY.databases.$database_id.mysqldump_options")

  local shared_options=''
  if [[ null != ${settings[@]} ]]; then
    for option in ${settings[@]}; do
      shared_options=" $shared_options --$option"
    done
  fi

  local options=''
  local defaults_file=$(ldp_db_echo_conf_filepath "$LOCAL_ENV_ID" "$database_id")
  local db_name
  ! db_name=$(mysql_get_database_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$db_name" && return 1

  # This will write the table structure to the export file.
  local structure_tables=$(ldp_get_db_export_tables --structure "$LOCAL_ENV_ID" "$database_id")
  if [[ "$structure_tables" ]]; then
    options="$shared_options --add-drop-table --no-data "
    mysqldump --defaults-file="$defaults_file"$options "$db_name" $structure_tables >> "$save_as"
  fi
  # This will write the data to the export file.s
  local data_tables=$(ldp_get_db_export_tables --data "$LOCAL_ENV_ID" "$database_id")
  if [[ "$data_tables" ]]; then
    options="$shared_options --skip-add-drop-table --no-create-info"
    mysqldump --defaults-file="$defaults_file"$options "$db_name" $data_tables >> "$save_as"
  fi

  if [[ ! "$structure_tables" ]] || [[ ! "$data_tables" ]]; then
    fail_because "No tables to be exported"
  fi

  has_failed && return 1
  succeed_because "Saved to $save_as"
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

  local defaults_file=$(ldp_db_echo_conf_filepath "$LOCAL_ENV_ID" "$LOCAL_DATABASE_ID")

  mysql --defaults-file="$defaults_file" $db_name < $path_to_dumpfile
}

function mysql_pull_databases() {
  for DATABASE_ID in "${DATABASE_IDS[@]}"; do

    # TODO Export remote database.
    # TODO Download remote database.
    # TODO Export local database for rollback.
    # TODO Import Remote database to local database

    workflow=$(get_option 'processor')
    if [[ ! "$workflow" ]]; then
      eval $(get_config_as "workflow" "environments.$LOCAL_ENV_KEY.processors.$COMMAND")
    fi
    if [[ "$workflow" ]]; then
      ENVIRONMENT_ID="$LOCAL_ENV_ID"
      eval $(get_config_as -a includes "file_groups.${key}.include")
      for include in "${includes[@]}"; do
        for FILEPATH in "$destination"/$include; do
          if [[ -f "$FILEPATH" ]]; then
            SHORTPATH=$(path_unresolve "$destination" "$FILEPATH")
            SHORTPATH=${SHORTPATH#/}
            execute_workflow "$workflow" || exit_with_failure
          fi
         done
      done
    fi
  done
}
