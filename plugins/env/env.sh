#!/usr/bin/env bash

# Remove the mysql.*.cnf files from the cache directory
#
# Returns 0 if successful, 1 otherwise.
function env_on_clear_cache() {
  database_delete_all_defaults_files || return 1
  database_delete_all_name_files || return 1
  return 0
}

# Rebuild configuration files after a cache clear.
#
# Returns 0 if successful, 1 otherwise.
function env_on_rebuild_config() {
  eval $(get_config_keys_as "database_ids" "environments.$LOCAL_ENV_ID.databases")
  for database_id in "${database_ids[@]}"; do
    local db_pointer="environments.$LOCAL_ENV_ID.databases.${database_id}"
    eval $(get_config_as "plugin" "$db_pointer.plugin")
    [[ "$plugin" != 'env' ]] && continue;

    eval $(get_config_path_as "path" "$db_pointer.path")
    [[ -f "$path" ]] || exit_with_failure "Missing .env file at: $path"

    exit_with_failure_if_empty_config "path" "$db_pointer.path"
    eval $(get_config_as "var" "$db_pointer.var")
    exit_with_failure_if_empty_config "var" "$db_pointer.var"
    ! result=$($CLOUDY_PHP "$PLUGINS_DIR/env/env.php" "$path" "$var") && exit_with_failure "$result"
    json_set "$result"

    local filepath=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
    local path_label="$(path_unresolve "$APP_ROOT" "$filepath")"

    # Create the .cnf file
    local directory=""$(dirname "$filepath")""
    sandbox_directory "$directory"
    ! mkdir -p "$directory" && fail_because "Could not create $directory" && return 1
    ! touch "$filepath" && fail_because "Could not create $path_label" && return 1
    ! chmod 0600 "$filepath" && fail_because "Failed with chmod 0600 $path_label" && return 1

    local host="$(json_get_value '0.external_connection.host')"
    local port="$(json_get_value '0.external_connection.port')"
    local user="$(json_get_value '0.creds.user')"
    local password="$(json_get_value '0.creds.password')"

    echo "[client]" >"$filepath"
    echo "host=\"$host\"" >>"$filepath"
    [[ "$port" ]] && echo "port=\"$port\"" >>"$filepath"
    echo "user=\"$user\"" >>"$filepath"
    echo "password=\"$password\"" >>"$filepath"
    [[ "$protocol" ]] && echo "protocol=\"$protocol\"" >>"$filepath"
    ! chmod 0400 "$filepath" && fail_because "Failed with chmod 0400 $path_label" && return 1

    # Save the database name
    name_path="$(database_get_cached_name_filepath "$LOCAL_ENV_ID" "$database_id")"
    local name_label="$(path_unresolve "$APP_ROOT" "$name_path")"
    echo "$(json_get_value '0.creds.database')" > $name_path
    succeed_because "$name_label has been created."
  done
  has_failed && return 1
  succeed_because "$path_label has been created."
  return 0
}

# @see database_get_name
function env_on_database_name() {
  local environment_id="$1"
  local database_id="$2"

  local db_name
  local filepath
  filepath="$(database_get_cached_name_filepath "$environment_id" "$database_id")"
  [[ ! -f "$filepath" ]] && echo "Missing database name; try clearing caches." && return 1
  db_name=$(cat "$filepath")
  [[ "$db_name" ]] && echo "$db_name" && return 0
  echo "Env plugin cannot determine the database name." && return 1
}

function env_on_db_shell() {
  call_plugin mysql db_shell $@
}
function env_on_export_db() {
  call_plugin mysql export_db $@
}
function env_on_import_db() {
  call_plugin mysql import_db $@
}
function env_on_pull_db() {
  call_plugin mysql pull_db $@
}
