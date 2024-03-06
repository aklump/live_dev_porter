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

# Echo the path to a .conf file.
#
# $1 - The environment ID.
# $2 - The database ID (not the name, the ID!)
#
# Returns nothing.
function database_get_defaults_file() {
  local environment_id="$1"
  local database_id="$2"

  local defaults_file
  defaults_file=$(call_php_class_method "\AKlump\LiveDevPorter\Database\DatabaseGetDefaultsFile::__invoke($environment_id,$database_id)")
  if [[ $? -ne 0 ]]; then
    write_log_error "'${FUNCNAME[0]}' failed: $defaults_file"
    fail_because "$defaults_file" && return 1
  fi
  echo "$defaults_file"
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

  local connection_url
  connection_url=$(call_php_class_method "\AKlump\LiveDevPorter\Database\DatabaseGetConnectionUrl::__invoke($environment_id, $database_id)")
  if [[ $? -ne 0 ]]; then
    write_log_error "'${FUNCNAME[0]}' failed: $connection_url"
    fail_because "$connection_url" && return 1
  fi
  echo "$connection_url"
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

  local name
  name=$(call_php_class_method "\AKlump\LiveDevPorter\Database\DatabaseGetName::__invoke($environment_id,$database_id)")
  if [[ $? -ne 0 ]]; then
    write_log_error "'${FUNCNAME[0]}' failed: $name"
    fail_because "$name" && return 1
  fi
  echo "$name"
}

function database_get_cached_name_filepath() {
  local environment_id="$1"
  local database_id="$2"

  local filepath
  filepath=$(call_php_class_method "\AKlump\LiveDevPorter\Database\DatabaseGetDefaultsFile::__invoke($environment_id,$database_id)")
  if [[ $? -ne 0 ]]; then
    write_log_error "'${FUNCNAME[0]}' failed: $filepath"
    fail_because "$filepath" && return 1
  fi
  echo "$(dirname $filepath)/db_name.txt"
}
