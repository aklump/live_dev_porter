#!/usr/bin/env bash

# @file
#
# Provide shared database-related functions.
#

# Get the local export directory for
#
# $1 - The environment ID.
# $2 - The database ID.
#
# Echos the directory WITHOUT trailing slash.
function database_get_local_directory() {
  echo $(database_get_directory "$LOCAL_ENV_ID" "$@")
}

# Get filepath to save a dumpfile from one environment to another.
#
# $1 - The environment ID where the file is being saved.
# $3 - The environment ID where the database was exported from.
# $2 - The database ID that was the source of the export.
#
# Echos the directory WITHOUT trailing slash.
function database_get_directory() {
  local environment_id="$1"
  local database_environment_id="$2"
  local database_id="$3"

  local base="$CONFIG_DIR"
  if [[ "$environment_id" != $LOCAL_ENV_ID ]]; then
      eval $(get_config_as base "environments.$environment_id.base_path")
      base="$base/"$(basename $CONFIG_DIR)
  fi

  echo "$base/data/$database_environment_id/databases/$database_id"
}

# Get the table section of the mysqldump command based on config.
#
# $1 - The environment ID.
# $2 - The database ID for that environment.
#
# @option --structure Tables for structure export.
# @option --data Tables for data export.
#
function database_get_export_tables() {
  parse_args "$@"
  local environment_id="${parse_args__args[0]}"
  local database_id="${parse_args__args[1]}"
  local database_name="${parse_args__args[2]}"
  local workflow="${parse_args__args[3]}"

  local conditions
  local table_query
  local defaults_file
  table_query="SET group_concat_max_len = 40960;"
  table_query="${table_query} SELECT GROUP_CONCAT(table_name separator ' ') FROM information_schema.tables WHERE table_schema='$database_name'"

  if [[ "$parse_args__options__data" ]]; then
    # --structure || --data

    conditions="$(database_get_table_list_where "$database_id" "$workflow" "exclude_table_data")" || return
    table_query="${table_query}$conditions"
    conditions="$(database_get_table_list_where "$database_id" "$workflow" "include_table_data")" || return
    table_query="${table_query}$conditions"
  fi

  # Omit the tables listed in exclude_tables, YES this is needed here too.
  conditions="$(database_get_table_list_where "$database_id" "$workflow" "exclude_tables")" || return
  table_query="${table_query}$conditions"
  conditions="$(database_get_table_list_where "$database_id" "$workflow" "include_tables")" || return
  table_query="${table_query}$conditions"

  defaults_file=$(database_get_defaults_file "$environment_id" "$database_id")
  write_log_debug "mysql --defaults-file="$defaults_file" -AN -e"$table_query""
  result=$(mysql --defaults-file="$defaults_file" -AN -e"$table_query")
  [[ "$result" != NULL ]] && echo $result
}

# Determine if a given database is empty or has tables.
#
# $1 - The name of the database.
#
# Returns 0 if .
function database_has_tables() {
  local db_name="$1"

  table_query="select table_name from information_schema.tables where table_schema=\"$db_name\""
  result=$(mysql --defaults-file="$defaults_file" -AN -e"$table_query")
  [[ "$result" ]] || return 1
}

# Build a tablename query accounting for workflow table exclusions.
#
# $1 - The database ID.
# $2 - The workflow ID.
# $3 - The workflow item key, e.g. 'exclude_tables', 'exclude_table_data', 'include_tables', or 'include_table_data'
#
# Returns 0 and echos the where clause for table selection.  Returns 1 to
# indicate that all tables have been excluded, meaning no query should be run.
#
function database_get_table_list_where() {
  local database_id="$1"
  local workflow="$2"
  local workflow_key="$3"

  local array_csv__array
  local where
  local qualifier

  if [[ "exclude_tables" == "$workflow_key" ]] || [[ "exclude_table_data" == "$workflow_key" ]]; then
    qualifier='NOT '
  fi

  eval $(get_config_as -a tables "workflows.$workflow.databases.$database_id.$workflow_key")
  [[ ${#tables[@]} -eq 0 ]] && return 0

  array_csv__array=()
  for p in "${tables[@]}"; do

    # This converts glob-syntax to mysql-syntax; both works.
    p=${p/\*/\%}

    if [[ $p == "%" ]]; then
      # This is special, it means that all tables should be excluded this
      # function actually has nothing to do, it should echo nothing, meaning
      # there is modification of the table_schema query necessary.
      return 1
    elif [[ $p == *"%"* ]]; then
      where="$where AND table_name $qualifierLIKE '$p'"
    else
      array_csv__array=("${array_csv__array[@]}" "$p")
    fi
  done

  if [[ "${#array_csv__array[@]}" -gt 0 ]]; then
    where="$where AND table_name $qualifierIN ($(array_csv --single-quotes))"
  fi
  echo "$where"
}


# Echo the path to a .conf file.
#
# $1 - The environment ID.
# $2 - The database ID (not the name, the ID!)
#
# Returns nothing.
function database_get_defaults_file() {
  local environment_id="$1"
  local database_id="$2"

  echo "$CACHE_DIR/$environment_id/databases/$database_id/db.cnf"
}

# Echo a connection string for a database.
#
# e.g. mysql://<username>:<password>@<host>:<port>/<db_name>
#
# $1 - The environment ID.
# $2 - The database ID (not the name, the ID!)
#
# Returns nothing.
function database_get_connection_url() {
  local environment_id="$1"
  local database_id="$2"

  echo $($CLOUDY_PHP "$ROOT/php/connection_url.php" "$(database_get_defaults_file "$environment_id" "$database_id")")"$(database_get_name "$environment_id" "$database_id")"
}

# Delete all .cnf files for all environments and database.
#
# @see HOOK_on_clear_cache()
#
# Returns 0 if successful; 1 otherwise.
function database_delete_all_defaults_files(){
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

function database_delete_all_name_files() {
  local pattern=$(database_get_cached_name_filepath "*" "*")
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

# Echo the database name by environment ID && database ID.
#
# $1 - The environment ID.
# $1 - The database ID.
#
# @code
# local name
# ! name=$(database_get_name "$LOCAL_ENV_ID" "$database_id") && fail_because "$name" && return 1
# @endcode
#
# Returns 0 if .
function database_get_name() {
  local environment_id="$1"
  local database_id="$2"

  eval $(get_config_as plugin "environments.$environment_id.databases.$database_id.plugin")
  ! [[ "$plugin" ]] && echo "Missing plugin empty configuration value for environments.$environment_id.databases.$database_id.plugin" && return 1
  call_plugin $plugin database_name "$@"
}


function database_get_cached_name_filepath() {
  local environment_id="$1"
  local database_id="$2"

  local filepath
  filepath=$(database_get_defaults_file "$environment_id" "$database_id")
  echo "$(dirname $filepath)/db_name.txt"
}
