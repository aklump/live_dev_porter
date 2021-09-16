#!/usr/bin/env bash

# @file
#
# Provide shared database-related functions.
#

#
# Echo the basename of the last pulled database file.
#
function ldp_get_fetched_db_path() {
  path=$(ls "$FETCH_DB_PATH/"*.sql* 2> /dev/null)
  if [[ "$path" ]]; then
    echo "$path"
  fi
}

function ldp_delete_fetched_db() {
  local dumpfile=$(ldp_get_fetched_db_path)
  if [[ "$dumpfile" ]]; then
    if [ -f "$dumpfile" ]; then
      rm -v "$dumpfile" || fail_because "Could not delete $dumpfile"
    fi
  fi
  has_failed && return 1
  return 0
}

##
# Drop all local db tables
#
function ldp_db_drop_tables() {
  eval $(get_config_as "db_name" "environments.dev.database.name")
  local path_to_db_creds=$(ldp_get_db_creds_path)
  [ -f "$path_to_db_creds" ] || _generate_db_cnf || return 1
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

function ldp_get_db_creds_path() {
  echo "$CACHE_DIR/_cached.$(path_filename $SCRIPT).$LOCAL_ENV.cnf"
}

# These are the tables whose structure only should be dumped.
#
function ldp_get_db_export_structure_and_data_tables() {
  local table_query="SET group_concat_max_len = 40960;"
  table_query="${table_query} SELECT GROUP_CONCAT(table_name separator ' ')"

  eval $(get_config_as "db_name" "environments.dev.database.name")
  table_query="${table_query} FROM information_schema.tables WHERE table_schema='$db_name'"

  # Omit the tables listed in tables.ignore unless using '--all'.
  if ! has_option all; then
    eval $(get_config_as "ignore_tables" "environments.dev.export.exclude_tables_listed_in")
    local path="$EXPORT_DB_PATH/$ignore_tables"
    [ -f "$path" ] || touch "$path"
    table_query="${table_query}$(_build_where_not_query $path)"
  fi

  mysql --defaults-file="$(ldp_get_db_creds_path)" -AN -e"$table_query"
}

# These are the tables whose content only should be dumped
#
function ldp_get_db_export_data_only_tables() {
  eval $(get_config_as "db_name" "environments.dev.database.name")
  local table_query="SET group_concat_max_len = 40960;"
  table_query="${table_query} SELECT GROUP_CONCAT(table_name separator ' ')"
  table_query="${table_query} FROM information_schema.tables WHERE table_schema='$db_name'"

  # Omit the tables listed in data.ignore unless using '--all'.
  if ! has_option all; then
    eval $(get_config_as "ignore_data" "environments.dev.export.exclude_data_from_tables_listed_in")
    local path="$EXPORT_DB_PATH/$ignore_data"
    [ -f "$path" ] || touch "$path"
    table_query="${table_query}$(_build_where_not_query $path)"

    # Omit the tables listed in tables.ignore
    eval $(get_config_as "ignore_tables" "environments.dev.export.exclude_tables_listed_in")
    local path="$EXPORT_DB_PATH/$ignore_tables"
    table_query="${table_query}$(_build_where_not_query $path)"
  fi

  mysql --defaults-file="$(ldp_get_db_creds_path)" -AN -e"$table_query"
}

# Build a tablename query expanding wildcards from a file of tablenames
#
# $1 - string - Filepath to the list of tablenames.
#
function _build_where_not_query() {
  local path_to_table_list="$1"

  # Nothing to do if there is no file
  [ -f "$path_to_table_list" ] || return 0

  local csv
  local where
  while read p; do
    if [[ $p == *"%"* ]]; then
      where="$where AND table_name NOT LIKE '$p'"
    else
      csv="$csv,'$p'"
    fi
  done <"$path_to_table_list"

  csv=${csv#,}
  if [[ "$csv" ]]; then
    where="$where AND table_name NOT IN ($csv)"
  fi
  echo "$where"
}
