#!/usr/bin/env bash

# Remove the mysql.*.cnf files from the cache directory
#
# Returns 0 if successful, 1 otherwise.
function drupal_on_clear_cache() {
  database_delete_all_defaults_files || return 1
  database_delete_all_name_files || return 1
  return 0
}

# Rebuild configuration files after a cache clear.
#
# Returns 0 if successful, 1 otherwise.
function drupal_on_rebuild_config() {
  local db_pointer
  local directory
  local filepath
  local host
  local name_label
  local password
  local path_label
  local port
  local user
  eval $(get_config_keys_as "database_ids" "environments.$LOCAL_ENV_ID.databases")
  for database_id in "${database_ids[@]}"; do
    db_pointer="environments.$LOCAL_ENV_ID.databases.${database_id}"
    eval $(get_config_as "plugin" "$db_pointer.plugin")
    [[ "$plugin" != 'drupal' ]] && continue;

    eval $(get_config_path_as "settings" "$db_pointer.settings")
    exit_with_failure_if_config_is_not_path "settings" "$db_pointer.settings"

    eval $(get_config_as "drupal_db_key" "$db_pointer.database" "default")

    ! result=$($CLOUDY_PHP "$PLUGINS_DIR/drupal/drupal.php" "$settings" "$drupal_db_key") && exit_with_failure "$result"
    json_set "$result"

    filepath=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
    path_label="$(path_make_relative "$filepath" "$CLOUDY_BASEPATH")"

    # Create the .cnf file
    directory=""$(dirname "$filepath")""
    sandbox_directory "$directory"
    ! mkdir -p "$directory" && fail_because "Could not create $directory" && return 1
    ! touch "$filepath" && fail_because "Could not create $path_label" && return 1
    ! chmod 0600 "$filepath" && fail_because "Failed with chmod 0600 $path_label" && return 1

    host="$(json_get_value '0.external_connection.host')"
    port="$(json_get_value '0.external_connection.port')"
    user="$(json_get_value '0.creds.user')"
    password="$(json_get_value '0.creds.password')"

    echo "[client]" >"$filepath"
    echo "host=\"$host\"" >>"$filepath"
    [[ "$port" ]] && echo "port=\"$port\"" >>"$filepath"
    echo "user=\"$user\"" >>"$filepath"
    echo "password=\"$password\"" >>"$filepath"
    [[ "$protocol" ]] && echo "protocol=\"$protocol\"" >>"$filepath"
    ! chmod 0400 "$filepath" && fail_because "Failed with chmod 0400 $path_label" && return 1
    succeed_because "$path_label has been created."

    # Save the database name
    name_path="$(database_get_cached_name_filepath "$LOCAL_ENV_ID" "$database_id")"
    name_label="$(path_make_relative "$name_path" "$CLOUDY_BASEPATH")"
    echo "$(json_get_value '0.creds.database')" > $name_path
    succeed_because "$name_label has been created."
  done
  has_failed && return 1
  return 0
}

# @see database_get_name
function drupal_on_database_name() {
  local environment_id="$1"
  local database_id="$2"

  local db_name
  local filepath
  filepath="$(database_get_cached_name_filepath "$environment_id" "$database_id")"
  [[ ! -f "$filepath" ]] && echo "Missing database name; try clearing caches." && return 1
  db_name=$(cat "$filepath")
  [[ "$db_name" ]] && echo "$db_name" && return 0
  echo "Drupal plugin cannot determine the database name." && return 1
}

function drupal_on_configtest() {
  local run_our_tests
  run_our_tests=false
  eval $(get_config_keys_as "database_ids" "environments.$LOCAL_ENV_ID.databases")
  for database_id in "${database_ids[@]}"; do
    eval $(get_config_as "plugin" "environments.$LOCAL_ENV_ID.databases.${database_id}.plugin")
    [[ "$plugin" == 'drupal' ]] && run_our_tests=true && break
  done
  [[ "$run_our_tests" == false ]] && return 255

  for database_id in "${database_ids[@]}"; do
    local db_pointer="environments.$LOCAL_ENV_ID.databases.${database_id}"
    eval $(get_config_path_as "path" "$db_pointer.settings")
    echo_task "Able to read settings.php file for $LOCAL_ENV_ID database: $database_id."
    if [[ ! -f "$path" ]]; then
      echo_task_failed && fail
    else
      echo_task_completed
    fi
  done

  call_plugin mysql configtest "$@"
}
function drupal_on_db_shell() {
  call_plugin mysql db_shell "$@"
}
function drupal_on_export_db() {
  call_plugin mysql export_db "$@"
}
function drupal_on_import_db() {
  call_plugin mysql import_db "$@"
}
function drupal_on_pull_db() {
  call_remote_database_plugin pull_db "$@"
}
function drupal_on_push_db() {
  call_remote_database_plugin push_db "$@"
}
