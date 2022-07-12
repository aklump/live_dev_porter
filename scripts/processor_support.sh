#!/usr/bin/env bash


# Query the current database being processed.
#
# The result can be seen in the file indicated by $query_result, which is a
# filepath.
#
# $1 - The SQL statement to execute.
#
# Returns 0 if successful; 1 otherwise.
function query() {
  local query="$1"

  local defaults_file
  local db_name
  query_result="$CACHE_DIR/database_result.sql"
  defaults_file=$(ldp_db_echo_conf_filepath "$ENVIRONMENT_ID" "$DATABASE_ID")
  db_name=$(mysql_get_database_name "$ENVIRONMENT_ID" "$DATABASE_ID") || return 1
  mysql --defaults-file="$defaults_file" "$db_name" -e "$query" > "$query_result" || return 1
  # This removes the header row
  tail -n +2 "$query_result" > "$query_result.tmp" && mv "$query_result.tmp" "$query_result"
  return 0
}
