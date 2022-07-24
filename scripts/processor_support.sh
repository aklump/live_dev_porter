#!/usr/bin/env bash


# Query the current database being processed and echo a message.
#
# If the result succeeded the query will be echoed.  If it failed, it will be
# preceded by "Failed query: ..."  This behavior is consistent with plugins
# providing feedback via echo.
#
# The result of the query can be seen in the file indicated by $query_result,
# which is a filepath.
#
# $1 - The SQL statement to execute.
#
# Returns 0 if successful and echos query; 1 otherwise and echos failure message.
function query() {
  local query="$1"

  local defaults_file
  local db_name
  local feedback

  [[ "$LOCAL_ENV_ID" ]] || throw "Missing $LOCAL_ENV_ID;$0;in function ${FUNCNAME}();$LINENO"
  [[ "$DATABASE_ID" ]] || throw "Missing $DATABASE_ID;$0;in function ${FUNCNAME}();$LINENO"
  db_name=$(database_get_name "$LOCAL_ENV_ID" "$DATABASE_ID") ||  throw "$db_name;$0;in function ${FUNCNAME}();$LINENO"

  eval $(get_config_as "write_access" "environments.$LOCAL_ENV_ID.write_access" false)
  if [[ "$write_access" != true ]]; then
    feedback="query() can only be used if the environment \"$LOCAL_ENV_ID\" has write_access, you must change your configuration to allow this."
    write_log_error "$feedback"
    throw "$feedback;$0;in function ${FUNCNAME}();$LINENO"
  fi

  query_result="$CACHE_DIR/database_result.sql"
  defaults_file=$(database_get_defaults_file "$LOCAL_ENV_ID" "$DATABASE_ID")
  ! mysql --defaults-file="$defaults_file" "$db_name" -e "$query" > "$query_result" && echo "Failed query: $query" && return 1
  # This removes the header row
  tail -n +2 "$query_result" > "$query_result.tmp" && mv "$query_result.tmp" "$query_result"
  echo "$query" && return 0
}
