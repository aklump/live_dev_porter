#!/usr/bin/env bash

# @file
#
# Provide shared database-related functions.
#

# Echo the path to a .conf file.
#
# $1 - The environment ID.
# $2 - The database ID (not the name, the ID!)
#
# Returns nothing.
function ldp_db_echo_conf_filepath() {
  local environment_id="$1"
  local database_id="$2"

  echo "$CACHE_DIR/$environment_id/databases/$database_id/mysql.cnf"
}

function ldp_db_echo_export_directory() {
  local environment_id="$1"
  local database_id="$2"

  echo "$CONFIG_DIR/$environment_id/databases/$database_id/"
}

##
# Drop all local db tables
#
function ldp_db_drop_tables() {
  eval $(get_config_as "db_name" "environments.dev.database.name")
  local path_to_db_creds=$(ldp_get_db_creds_path dev)
  tables=$(mysql --defaults-file="$path_to_db_creds" $db_name -e 'SHOW TABLES' | awk '{ print $1}' | grep -v '^Tables')
  sql="DROP TABLE "
  for t in $tables; do
    sql="$sql\`$t\`,"
  done
  sql="${sql%,}"
  message="drop all tables"
  if mysql --defaults-file="$path_to_db_creds" $db_name -e "$sql"; then
    echo_pass "$message"
  else
    echo_pass "$message" && fail
  fi
  has_failed && return 1
  return 0
}

# Get the absolute path the the db creds for an environment.
#
# $1 - The environment ID.
#
function ldp_get_db_creds_path() {
  local env_id=$1

  local env
  eval $(get_config_as "env" "environments.$env_id.id")
  exit_with_failure_if_empty_config "env" "environments.$env_id.id"
  echo "$CACHE_DIR/_cached.$(path_filename $SCRIPT).$env.cnf"
}

# Get the table section of the mysqldump command based on config.
#
# $1 - The environment ID.
# $2 - The database ID for that environment.
#
# @option --structure Tables for structure export.
# @option --data Tables for data export.
#
function ldp_get_db_export_tables() {
  local environment_id="$1"
  local database_id="$2"

  parse_args "$@"
  environment_id="${parse_args__args[0]}"
  database_id="${parse_args__args[1]}"

  local table_query="SET group_concat_max_len = 40960;"
  table_query="${table_query} SELECT GROUP_CONCAT(table_name separator ' ')"

  local environment_key=$(echo_config_key_by_id "environments" "$environment_id")
  eval $(get_config_as "db_name" "environments.$environment_key.databases.$database_id.name")
  table_query="${table_query} FROM information_schema.tables WHERE table_schema='$db_name'"

  # Look at the configuration for explicit tables unless using --all.
  if ! has_option all; then

    if [[ "$parse_args__options__data" ]]; then
      local database_key=$(echo_config_key_by_id "databases" "$database_id")
      table_query="${table_query}$(_build_where_not_query "databases.$database_key.exclude_table_data")"
    fi

    # Omit the tables listed in tables.ignore, again this is needed here too.
    local database_key=$(echo_config_key_by_id "databases" "$database_id")
    table_query="${table_query}$(_build_where_not_query "databases.$database_key.exclude_tables")"
  fi

  local path_to_db_creds=$(ldp_db_echo_conf_filepath "$environment_id" "$database_id")
  mysql --defaults-file="$path_to_db_creds" -AN -e"$table_query"
}

# Build a tablename query expanding wildcards from a file of tablenames
#
# $1 - string - Filepath to the list of tablenames.
#
function _build_where_not_query() {
  local config_list_lookup="$1"

  eval $(get_config_as -a "tables" "$config_list_lookup")
  [[ ${#tables[@]} -eq 0 ]] && return 0

  local array_csv__array=()
  local where
  for p in "${tables[@]}"; do

    # This converts glob-syntax to mysql-syntax; both works.
    p=${p/\*/\%}

    if [[ $p == *"%"* ]]; then
      where="$where AND table_name NOT LIKE '$p'"
    else
      array_csv__array=("${array_csv__array[@]}" "$p")
    fi
  done

  if [[ "${#array_csv__array[@]}" ]]; then
    where="$where AND table_name NOT IN ($(array_csv --single-quotes))"
  fi
  echo "$where"
}
