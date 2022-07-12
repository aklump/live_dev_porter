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
function database_get_defaults_file() {
  local environment_id="$1"
  local database_id="$2"

  echo "$CACHE_DIR/$environment_id/databases/$database_id/db.cnf"
}

function database_get_export_directory() {
  local environment_id="$1"
  local database_id="$2"

  echo "$CONFIG_DIR/$environment_id/databases/$database_id/"
}

##
# Drop all local db tables
#
function database_drop_tables() {
  throw "This is not yet working;$0;in function ${FUNCNAME}();$LINENO"
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

  # Look at the configuration for explicit tables unless using --all.
  if [[ "$parse_args__options__data" ]]; then
    conditions="$(database_get_table_list_where "$database_id" "$workflow" "exclude_table_data")" || return
    table_query="${table_query}$conditions"
  fi

  # Omit the tables listed in tables.ignore, again this is needed here too.
  conditions="$(database_get_table_list_where "$database_id" "$workflow" "exclude_tables")" || return
  table_query="${table_query}$conditions"

  defaults_file=$(database_get_defaults_file "$environment_id" "$database_id")
  write_log_debug "mysql --defaults-file="$defaults_file" -AN -e"$table_query""
  mysql --defaults-file="$defaults_file" -AN -e"$table_query"
}

# Build a tablename query accounting for workflow table exclusions.
#
# $1 - The database ID.
# $2 - The workflow ID.
# $3 - The workflow item key, e.g. 'exclude_tables' or 'exclude_table_data'.
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
  eval $(get_config_keys_as workflow_keys "workflows.$workflow")
  [[ ${#workflow_keys[@]} -eq 0 ]] && return 0

  tables=()
  for i in "${workflow_keys[@]}"; do
     eval $(get_config_as workflow_database "workflows.$workflow.$i.database")
     if [[ "$workflow_database" == "$database_id" ]]; then
       eval $(get_config_as -a workflow_tables "workflows.$workflow.$i.$workflow_key")
       tables=("${tables[@]}" "${workflow_tables[@]}")
     fi
  done

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
